#!/usr/bin/env bash
# setup-postgres.sh
# Idempotent setup for PostgreSQL 16 on dnf-based Linux (Fedora/RHEL/CentOS stream)
#
# WARNING: Replace password variables or export them from a secure source before running.
# Running this script will modify /var/lib/pgsql/data/* and restart the database service.

set -euo pipefail
IFS=$'\n\t'

# --- User-editable variables ---
PG_VERSION=16
POSTGRES_PW="${POSTGRES_PW:-VenkY@007}"   # change or export before running
DBADMIN_NAME="${DBADMIN_NAME:-dbadmin}"
DBADMIN_PW="${DBADMIN_PW:-Admin@123}"                 # change or export before running

# --- Internal variables ---
PG_PKG="postgresql${PG_VERSION}-server"
PG_DATA_DIR="/var/lib/pgsql/data"
PG_CONF="${PG_DATA_DIR}/postgresql.conf"
PG_HBA="${PG_DATA_DIR}/pg_hba.conf"
PG_SETUP="/usr/bin/postgresql-setup"
SYSTEMCTL=$(command -v systemctl || true)
DNF=$(command -v dnf || true)

if [[ -z "$DNF" ]]; then
  echo "Error: dnf not found. This script expects a dnf-based system."
  exit 1
fi

echo "=== PostgreSQL setup script ==="
echo "Postgres package: ${PG_PKG}"
echo "Postgres data dir: ${PG_DATA_DIR}"
echo

# 1) Update packages and install postgresql server package (if not installed)
echo "-> Updating package metadata and installing ${PG_PKG} (if missing)"
sudo dnf update -y
if ! rpm -q "${PG_PKG}" >/dev/null 2>&1; then
  sudo dnf install -y "${PG_PKG}"
else
  echo "${PG_PKG} already installed."
fi

# 2) Initialize DB if not initialized
if [[ ! -f "${PG_DATA_DIR}/PG_VERSION" ]]; then
  if [[ -x "${PG_SETUP}" ]]; then
    echo "-> Initializing database with ${PG_SETUP} --initdb"
    sudo "${PG_SETUP}" --initdb
  else
    echo "Error: ${PG_SETUP} not found or not executable. Cannot initdb."
    exit 2
  fi
else
  echo "-> Database already initialized (found ${PG_DATA_DIR}/PG_VERSION). Skipping initdb."
fi

# 3) Ensure postgresql service is started and enabled
if [[ -n "$SYSTEMCTL" ]]; then
  echo "-> Starting and enabling postgresql service"
  sudo systemctl start postgresql
  sudo systemctl enable postgresql
else
  echo "Warning: systemctl not found; please start postgresql manually."
fi

# 4) Update postgresql.conf: set listen_addresses = '*'
echo "-> Ensuring listen_addresses = '*' in ${PG_CONF}"
if [[ -f "${PG_CONF}" ]]; then
  # If line exists (commented or uncommented), replace it. Otherwise append.
  sudo sed -i.bak -E "s/^#?[[:space:]]*listen_addresses[[:space:]]*=.*/listen_addresses = '*'/g" "${PG_CONF}" || true
  if ! sudo grep -Eq "^[[:space:]]*listen_addresses[[:space:]]*=" "${PG_CONF}"; then
    echo "listen_addresses = '*'" | sudo tee -a "${PG_CONF}" >/dev/null
  fi
else
  echo "Error: ${PG_CONF} not found. DB init may have failed."
  exit 3
fi

# 5) Update pg_hba.conf:
# - Change IPv4 local connections line to md5
# - Add "host all all 0.0.0.0/0 md5" if not present
echo "-> Modifying ${PG_HBA} to require md5 for local IPv4 and allow remote connections (0.0.0.0/0)"
if [[ -f "${PG_HBA}" ]]; then
  # Replace the specific IPv4 local connections line (127.0.0.1/32) to md5
  # This tries to match both commented and uncommented lines robustly.
  sudo sed -i.bak -E "s@^(\\s*host\\s+all\\s+all\\s+127\\.0\\.0\\.1/32\\s+)\\S+@\\1md5@g" "${PG_HBA}"

  # Ensure the global remote allow line exists (don't duplicate)
  if ! sudo grep -Eq "^[[:space:]]*host[[:space:]]+all[[:space:]]+all[[:space:]]+0\\.0\\.0\\.0/0[[:space:]]+md5" "${PG_HBA}"; then
    echo -e "\n# Allow remote user connections from any IPv4 address (use firewall to restrict access)\nhost    all             all             0.0.0.0/0               md5" | sudo tee -a "${PG_HBA}" >/dev/null
  else
    echo "Remote allow rule already present in ${PG_HBA}."
  fi
else
  echo "Error: ${PG_HBA} not found."
  exit 4
fi

# 6) Restart service to apply config changes
echo "-> Restarting postgresql to apply configuration changes"
if [[ -n "$SYSTEMCTL" ]]; then
  sudo systemctl restart postgresql
else
  echo "Warning: systemctl not found; please restart postgresql manually."
fi

# 7) Switch to postgres user and run SQL commands to set passwords and roles.
# Use sudo -u postgres psql -c "..." for each statement (idempotent checks included)

echo "-> Configuring DB users and roles"

# Update postgres user password
echo "Setting password for postgres user (via ALTER USER)..."
sudo -u postgres psql -v ON_ERROR_STOP=1 --username=postgres --no-align -c "ALTER USER postgres WITH PASSWORD '${POSTGRES_PW}';"

# Verify postgres version (optional)
echo "PostgreSQL version:"
sudo -u postgres psql -c "SELECT VERSION();" || true

# Create dbadmin role if not exists, set password and grant privileges
echo "Creating/Altering role ${DBADMIN_NAME} and granting privileges..."
sudo -u postgres psql -v ON_ERROR_STOP=1 --username=postgres <<-SQL
-- Create role if not exists
DO
\$do\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${DBADMIN_NAME}') THEN
      CREATE ROLE ${DBADMIN_NAME} WITH LOGIN PASSWORD '${DBADMIN_PW}';
   ELSE
      ALTER ROLE ${DBADMIN_NAME} WITH PASSWORD '${DBADMIN_PW}';
   END IF;
END
\$do\$;

-- Grant all privileges on the default 'postgres' database to dbadmin
GRANT ALL PRIVILEGES ON DATABASE postgres TO ${DBADMIN_NAME};

-- Grant createdb, createrole, and superuser flags as requested
ALTER ROLE ${DBADMIN_NAME} CREATEDB CREATEROLE SUPERUSER;
SQL

echo
echo "=== Completed PostgreSQL setup ==="
echo "Important: Use firewall (firewalld/iptables) to restrict access to PostgreSQL port (5432)"
echo "You can test remote connectivity from a client with: psql -h <server-ip> -U ${DBADMIN_NAME} -W -d postgres"
echo "Remember to replace default passwords with secure secrets and avoid hard-coding in production."
