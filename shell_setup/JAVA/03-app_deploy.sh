#!/usr/bin/env bash
# deploy-2tier-app.sh
# Installs git, clones repo, runs initdb.sql, updates app props, builds with Maven and deploys WAR to Tomcat.
#
# Usage: edit variables below if needed, then:
#   sudo ./deploy-2tier-app.sh

set -euo pipefail
IFS=$'\n\t'

# ---------- CONFIG (edit as needed) ----------
REPO_URL="${REPO_URL:-https://github.com/sapsecops/2-tier-java-App.git}"
CLONE_PARENT="${CLONE_PARENT:-/home/ec2-user}"
REPO_DIR_NAME="${REPO_DIR_NAME:-2-tier-java-App}"
BRANCH="${BRANCH:-01-Local-setup-Prod}"

# DB info for running initdb.sql and updating application.properties
DB_HOST="${DB_HOST:-172.31.16.207}"
DB_PORT="${DB_PORT:-5432}"
DB_ADMIN_USER="${DB_ADMIN_USER:-dbadmin}"
DB_ADMIN_PW="${DB_ADMIN_PW:-Admin@123}"
DB_NAME="${DB_NAME:-postgres}"
initdb="${initdb:-postgres}"
# application.properties DB values to write
APP_DB_URL="${APP_DB_URL:-jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}}"
APP_DB_USER="${APP_DB_USER:-dbadmin}"
APP_DB_PASSWORD="${APP_DB_PASSWORD:-Admin@123}"

# Paths
APP_BASE="${CLONE_PARENT}/${REPO_DIR_NAME}"
APP_PROPERTIES_REL="src/main/resources/application.properties"
INITDB_REL="initdb.sql"   # relative to APP_BASE (if init file at repo root)
TOMCAT_WEBAPPS_DIR="${TOMCAT_WEBAPPS_DIR:-/opt/tomcat/webapps}"
DEPLOY_WAR_NAME="${DEPLOY_WAR_NAME:-SSO.war}"

# Maven invocation (will run in ec2-user login shell)
MVN_CMD="${MVN_CMD:-mvn}"

# ---------- END CONFIG ----------
sudo chown -R ec2-user:ec2-user ${APP_BASE}
sudo chmod -R u+w ${APP_BASE}

log(){ echo "==> $*"; }
err(){ echo "ERROR: $*" >&2; exit 1; }

if [[ $EUID -ne 0 ]]; then
  log "It's recommended to run this script with sudo or as root. The script will still use sudo for privileged operations."
fi

log "Starting deployment for repo ${REPO_URL} (branch ${BRANCH})"

# 1. Install Git
log "Installing git..."
if command -v yum >/dev/null 2>&1; then
  sudo yum install -y git
elif command -v dnf >/dev/null 2>&1; then
  sudo dnf install -y git
else
  err "Neither yum nor dnf available. Please install git manually."
fi

# 2. Clone repo (or update)
mkdir -p "${CLONE_PARENT}"
cd "${CLONE_PARENT}"

if [[ -d "${APP_BASE}/.git" ]]; then
  log "Repository already exists at ${APP_BASE} — fetching updates and switching to branch ${BRANCH}"
  sudo -u ec2-user git -C "${APP_BASE}" fetch --all --prune || true
  # Attempt to checkout target branch
  sudo -u ec2-user git -C "${APP_BASE}" checkout "${BRANCH}" || true
  sudo -u ec2-user git -C "${APP_BASE}" pull --ff-only origin "${BRANCH}" || true
else
  log "Cloning ${REPO_URL} into ${CLONE_PARENT}"
  sudo -u ec2-user git clone "${REPO_URL}" "${APP_BASE}"
  # Checkout branch (try remote branch if not present locally)
  if sudo -u ec2-user git -C "${APP_BASE}" rev-parse --verify "${BRANCH}" >/dev/null 2>&1; then
    sudo -u ec2-user git -C "${APP_BASE}" checkout "${BRANCH}"
  else
    sudo -u ec2-user git -C "${APP_BASE}" fetch origin "${BRANCH}" || true
    sudo -u ec2-user git -C "${APP_BASE}" checkout -b "${BRANCH}" "origin/${BRANCH}" || true
  fi
fi

# 3. Install PostgreSQL client (psql)
log "Installing PostgreSQL client tools..."
if command -v dnf >/dev/null 2>&1; then
  sudo dnf update -y
  sudo dnf install -y postgresql16 || sudo dnf install -y postgresql
elif command -v yum >/dev/null 2>&1; then
  sudo yum update -y
  sudo yum install -y postgresql16 || sudo yum install -y postgresql
else
  err "No package manager found (yum/dnf). Install postgresql client manually."
fi

if ! command -v psql >/dev/null 2>&1; then
  err "psql not available after install. Check package names for your distribution."
fi

# 4. Run initdb.sql (if present)
INITDB_FULL="${APP_BASE}/${INITDB_REL}"
if [[ -f "${INITDB_FULL}" ]]; then
  log "Found init SQL at ${INITDB_FULL}. Executing on ${DB_HOST}:${DB_PORT} as ${DB_ADMIN_USER}"
  PGPASSWORD="${DB_ADMIN_PW}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_ADMIN_USER}" -d "${initdb}" -f "${INITDB_FULL}"
  log "initdb.sql executed."
else
  log "No initdb.sql found at ${INITDB_FULL}. Skipping DB initialization."
fi

# 5. Update application.properties
APP_PROPERTIES="${APP_BASE}/${APP_PROPERTIES_REL}"
if [[ -f "${APP_PROPERTIES}" ]]; then
  log "Backing up and updating ${APP_PROPERTIES} with DB connection values"
  sudo cp -a "${APP_PROPERTIES}" "${APP_PROPERTIES}.bak.$(date +%s)"
  sudo -u ec2-user bash -c "awk \
    -v url='spring.datasource.url=${APP_DB_URL}' \
    -v user='spring.datasource.username=${APP_DB_USER}' \
    -v pw='spring.datasource.password=${APP_DB_PASSWORD}' \
    'BEGIN{u=0;usr=0;pwf=0} \
     { if (\$0 ~ /^spring\\.datasource\\.url\\s*=.*/) { print url; u=1; next } \
       if (\$0 ~ /^spring\\.datasource\\.username\\s*=.*/) { print user; usr=1; next } \
       if (\$0 ~ /^spring\\.datasource\\.password\\s*=.*/) { print pw; pwf=1; next } \
       print \$0 } \
     END{ if(!u) print url; if(!usr) print user; if(!pwf) print pw }' \
    < \"${APP_PROPERTIES}\" > \"${APP_PROPERTIES}.tmp\" && mv \"${APP_PROPERTIES}.tmp\" \"${APP_PROPERTIES}\""
  log "application.properties updated (backup created)."
else
  log "application.properties not found at ${APP_PROPERTIES}. Please edit DB credentials manually if required."
fi

# 6. Fix permissions if permission issues
log "Fixing ownership and permissions under ${CLONE_PARENT}/${REPO_DIR_NAME}"
sudo chown -R ec2-user:ec2-user "${APP_BASE}"
sudo chmod -R u+rwX "${APP_BASE}"

# 7. Build with Maven (run in ec2-user login shell to ensure mvn is in PATH)
log "Preparing to build with Maven as ec2-user (login shell)"

# Detect mvn path (fallback to /opt/maven/bin/mvn)
MVN_PATH="$(command -v mvn 2>/dev/null || true)"
if [[ -z "${MVN_PATH}" && -x "/opt/maven/bin/mvn" ]]; then
  MVN_PATH="/opt/maven/bin/mvn"
fi
if [[ -z "${MVN_PATH}" ]]; then
  err "mvn not found. Ensure Maven is installed and available in PATH or at /opt/maven/bin/mvn"
fi

# detect java (optional)
JAVA_BIN="$(command -v java || true)"
JAVA_HOME_DERIVED=""
if [[ -n "${JAVA_BIN}" ]]; then
  JAVA_HOME_DERIVED="$(dirname "$(dirname "${JAVA_BIN}")")" || true
  log "Detected java: ${JAVA_BIN}, inferred JAVA_HOME=${JAVA_HOME_DERIVED}"
else
  log "java not detected in PATH - ensure java is installed or the build will fail"
fi

# run mvn as ec2-user login shell and cd into project dir inside that shell
if [[ -n "${JAVA_HOME_DERIVED}" ]]; then
  LOGIN_BUILD_CMD="cd '${APP_BASE}' && export JAVA_HOME='${JAVA_HOME_DERIVED}' && export PATH='${JAVA_HOME_DERIVED}/bin:/opt/maven/bin:\$PATH' && '${MVN_PATH}' clean package -DskipTests"
else
  LOGIN_BUILD_CMD="cd '${APP_BASE}' && export PATH='/opt/maven/bin:\$PATH' && '${MVN_PATH}' clean package -DskipTests"
fi

log "Executing build inside ec2-user login shell..."
sudo -i -u ec2-user bash -lc "${LOGIN_BUILD_CMD}" || {
  echo "================================================================"
  echo "Maven build failed. Diagnostics:"
  sudo -u ec2-user bash -lc "pwd; ls -la '${APP_BASE}' || true; which mvn || true; mvn -version || true; echo \$PATH"
  echo "================================================================"
  err "Maven build failed. See diagnostics above."
}

log "Maven build succeeded."

# 8. Locate WAR(s) and deploy to Tomcat
log "Searching for generated WAR files under ${APP_BASE}/target"
WAR_FILES=( $(find "${APP_BASE}/target" -maxdepth 1 -type f -name "*.war" -print) )
if [[ ${#WAR_FILES[@]} -eq 0 ]]; then
  err "No WAR found in ${APP_BASE}/target. Build may not have produced a WAR."
fi

# Ensure Tomcat webapps dir exists
if [[ ! -d "${TOMCAT_WEBAPPS_DIR}" ]]; then
  err "Tomcat webapps dir ${TOMCAT_WEBAPPS_DIR} not found. Ensure Tomcat is installed and path is correct."
fi

# Copy and optionally rename first WAR to DEPLOY_WAR_NAME
FIRST_WAR="${WAR_FILES[0]}"
log "Deploying ${FIRST_WAR} to ${TOMCAT_WEBAPPS_DIR}/${DEPLOY_WAR_NAME}"
sudo cp -f "${FIRST_WAR}" "${TOMCAT_WEBAPPS_DIR}/${DEPLOY_WAR_NAME}"
# ensure ownership (tomcat user may be different; if you used tomcat user earlier, adjust)
if id -u tomcat >/dev/null 2>&1; then
  sudo chown tomcat:tomcat "${TOMCAT_WEBAPPS_DIR}/${DEPLOY_WAR_NAME}" || true
fi

# 9. Restart tomcat service if present (to pick up new war)
if systemctl list-units --full -all | grep -Fq "tomcat.service"; then
  log "Restarting tomcat.service"
  sudo systemctl restart tomcat
else
  log "tomcat.service not found. If Tomcat is running, restart it manually to pick up the new WAR."
fi

log "Deployment finished. Deployed WAR: ${TOMCAT_WEBAPPS_DIR}/${DEPLOY_WAR_NAME}"
log "If the application fails to start, check Tomcat logs (e.g. /opt/tomcat/logs/catalina.out) and application logs."

exit 0
