#!/usr/bin/env bash
# setup-tomcat.sh
# Idempotent installer for Apache Tomcat 10.1.48 on dnf/yum based Linux.
#
# Usage:
#   sudo ./setup-tomcat.sh
#
# Edit variables below before running if you want different versions/paths.

set -euo pipefail
IFS=$'\n\t'

# ---------- USER CONFIG ----------
TOMCAT_GROUP="${TOMCAT_GROUP:-tomcat}"
TOMCAT_USER="${TOMCAT_USER:-tomcat}"
TOMCAT_INSTALL_DIR="${TOMCAT_INSTALL_DIR:-/opt/tomcat}"
TOMCAT_TMP_DIR="${TOMCAT_TMP_DIR:-/tmp}"
TOMCAT_VERSION="${TOMCAT_VERSION:-10.1.49}"
TOMCAT_ARCHIVE="apache-tomcat-${TOMCAT_VERSION}.tar.gz"
TOMCAT_DOWNLOAD_URL="${TOMCAT_DOWNLOAD_URL:-https://dlcdn.apache.org/tomcat/tomcat-10/v${TOMCAT_VERSION}/bin/${TOMCAT_ARCHIVE}}"
SYSTEMD_UNIT="/etc/systemd/system/tomcat.service"

# Tomcat manager credentials (change before production!)
TOMCAT_MANAGER_USER="${TOMCAT_MANAGER_USER:-tomcat}"
TOMCAT_MANAGER_PW="${TOMCAT_MANAGER_PW:-tomcat}"

# JAVA_HOME - set to your java home if different
# Default tries /usr/lib/jvm/java-17-amazon-corretto or /usr/lib/jvm/jre
DEFAULT_JAVA_HOME="/usr/lib/jvm/java-17-amazon-corretto"
FALLBACK_JAVA_HOME="/usr/lib/jvm/jre"
JAVA_HOME="${JAVA_HOME:-${DEFAULT_JAVA_HOME}}"
if [[ ! -d "${JAVA_HOME}" ]]; then
  if [[ -d "${FALLBACK_JAVA_HOME}" ]]; then
    JAVA_HOME="${FALLBACK_JAVA_HOME}"
  else
    # last fallback: try to discover java path
    JAVA_BIN=$(command -v java || true)
    if [[ -n "${JAVA_BIN}" ]]; then
      JAVA_HOME="$(dirname "$(dirname "${JAVA_BIN}")")"
    fi
  fi
fi

# ---------- end user config ----------

echo "=== Tomcat installer ==="
echo "Tomcat version: ${TOMCAT_VERSION}"
echo "Install dir: ${TOMCAT_INSTALL_DIR}"
echo "Tomcat user: ${TOMCAT_USER}:${TOMCAT_GROUP}"
echo "Download URL: ${TOMCAT_DOWNLOAD_URL}"
echo "JAVA_HOME: ${JAVA_HOME:-(not found)}"
echo

# 1) create group if not exists
if ! getent group "${TOMCAT_GROUP}" >/dev/null; then
  echo "-> Creating group ${TOMCAT_GROUP}"
  sudo groupadd "${TOMCAT_GROUP}"
else
  echo "-> Group ${TOMCAT_GROUP} already exists"
fi

# 2) create user if not exists (no login shell, home = install dir)
if ! id -u "${TOMCAT_USER}" >/dev/null 2>&1; then
  echo "-> Creating user ${TOMCAT_USER}"
  sudo useradd -g "${TOMCAT_GROUP}" -d "${TOMCAT_INSTALL_DIR}" -s /bin/false "${TOMCAT_USER}"
else
  echo "-> User ${TOMCAT_USER} already exists"
fi

# 3) download tomcat archive if not present
cd "${TOMCAT_TMP_DIR}"
if [[ ! -f "${TOMCAT_ARCHIVE}" ]]; then
  echo "-> Downloading ${TOMCAT_ARCHIVE}"
  sudo wget -q "${TOMCAT_DOWNLOAD_URL}" -O "${TOMCAT_ARCHIVE}"
else
  echo "-> Archive ${TOMCAT_ARCHIVE} already present in ${TOMCAT_TMP_DIR}"
fi

# 4) ensure target dir exists and extract (strip-components=1 to extract into /opt/tomcat)
if [[ -d "${TOMCAT_INSTALL_DIR}" ]]; then
  echo "-> ${TOMCAT_INSTALL_DIR} already exists. We'll update files by extracting over it."
else
  echo "-> Creating ${TOMCAT_INSTALL_DIR}"
  sudo mkdir -p "${TOMCAT_INSTALL_DIR}"
fi

echo "-> Extracting Tomcat into ${TOMCAT_INSTALL_DIR}"
# Use a temp dir to extract then move to owner to avoid partial state for users
sudo tar -xzf "${TOMCAT_ARCHIVE}" -C "${TOMCAT_INSTALL_DIR}" --strip-components=1

# 5) configure permissions
echo "-> Setting ownership and permissions"
sudo chown -R "${TOMCAT_USER}":"${TOMCAT_GROUP}" "${TOMCAT_INSTALL_DIR}"
sudo chmod -R 755 "${TOMCAT_INSTALL_DIR}"

# 6) make startup/shutdown scripts executable
echo "-> Ensuring startup/shutdown scripts are executable"
if [[ -f "${TOMCAT_INSTALL_DIR}/bin/startup.sh" ]]; then
  sudo chmod +x "${TOMCAT_INSTALL_DIR}/bin/startup.sh"
fi
if [[ -f "${TOMCAT_INSTALL_DIR}/bin/shutdown.sh" ]]; then
  sudo chmod +x "${TOMCAT_INSTALL_DIR}/bin/shutdown.sh"
fi

# 7) create systemd unit file (overwrite if differs)
echo "-> Writing systemd unit to ${SYSTEMD_UNIT}"
sudo bash -c "cat > ${SYSTEMD_UNIT}" <<EOF
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

User=${TOMCAT_USER}
Group=${TOMCAT_GROUP}

Environment=\"JAVA_HOME=${JAVA_HOME}\"
Environment=\"CATALINA_PID=${TOMCAT_INSTALL_DIR}/temp/tomcat.pid\"
Environment=\"CATALINA_HOME=${TOMCAT_INSTALL_DIR}\"
Environment=\"CATALINA_BASE=${TOMCAT_INSTALL_DIR}\"
Environment=\"CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC\"
Environment=\"JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom\"

ExecStart=${TOMCAT_INSTALL_DIR}/bin/startup.sh
ExecStop=${TOMCAT_INSTALL_DIR}/bin/shutdown.sh

[Install]
WantedBy=multi-user.target
EOF

# 8) reload systemd and enable/start service
echo "-> Reloading systemd daemon"
sudo systemctl daemon-reload

echo "-> Enabling tomcat service"
sudo systemctl enable tomcat || true

echo "-> Starting tomcat service (or restarting if already running)"
if systemctl is-active --quiet tomcat; then
  sudo systemctl restart tomcat
else
  sudo systemctl start tomcat
fi

# 9) Install tomcat-users.xml (overwrite the <tomcat-users> content)
TOMCAT_USERS_FILE="${TOMCAT_INSTALL_DIR}/conf/tomcat-users.xml"
echo "-> Installing tomcat-users.xml at ${TOMCAT_USERS_FILE} (backup created if present)"

if [[ -f "${TOMCAT_USERS_FILE}" ]]; then
  sudo cp -a "${TOMCAT_USERS_FILE}" "${TOMCAT_USERS_FILE}.bak.$(date +%s)"
fi

sudo bash -c "cat > ${TOMCAT_USERS_FILE}" <<EOF
<?xml version='1.0' encoding='utf-8'?>
<tomcat-users>
  <role rolename=\"admin\"/>
  <role rolename=\"admin-gui\"/>
  <role rolename=\"manager\"/>
  <role rolename=\"admin-script\"/>
  <role rolename=\"manager-gui\"/>
  <role rolename=\"manager-script\"/>
  <role rolename=\"manager-jmx\"/>
  <role rolename=\"manager-status\"/>
  <user username=\"${TOMCAT_MANAGER_USER}\" password=\"${TOMCAT_MANAGER_PW}\" roles=\"admin,manager,admin-gui,admin-script,manager-gui,manager-script,manager-jmx,manager-status\"/>
</tomcat-users>
EOF

sudo chown "${TOMCAT_USER}":"${TOMCAT_GROUP}" "${TOMCAT_USERS_FILE}"
sudo chmod 640 "${TOMCAT_USERS_FILE}"

# 10) Install context.xml for manager to allow remote addresses (backup existing)
MANAGER_CONTEXT="${TOMCAT_INSTALL_DIR}/webapps/manager/META-INF/context.xml"
echo "-> Installing manager context at ${MANAGER_CONTEXT} (backup created if present)"
if [[ -f "${MANAGER_CONTEXT}" ]]; then
  sudo cp -a "${MANAGER_CONTEXT}" "${MANAGER_CONTEXT}.bak.$(date +%s)"
else
  # ensure directory exists
  sudo mkdir -p "$(dirname "${MANAGER_CONTEXT}")"
  sudo chown -R "${TOMCAT_USER}":"${TOMCAT_GROUP}" "$(dirname "${MANAGER_CONTEXT}")"
fi

sudo bash -c "cat > ${MANAGER_CONTEXT}" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Context antiResourceLocking="false" privileged="true" >
  <CookieProcessor className="org.apache.tomcat.util.http.Rfc6265CookieProcessor"
                   sameSiteCookies="strict" />
  <Valve className="org.apache.catalina.valves.RemoteAddrValve"
          allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1 |.*" />
  <Manager sessionAttributeValueClassNameFilter="java\.lang\.(?:Boolean|Integer|Long|Number|String)|org\.apache\.catalina\.filters\.CsrfPreventionFilter\$LruCache(?:\$1)?|java\.util\.(?:Linked)?HashMap"/>
</Context>
EOF

sudo chown "${TOMCAT_USER}":"${TOMCAT_GROUP}" "${MANAGER_CONTEXT}"
sudo chmod 640 "${MANAGER_CONTEXT}"

# 11) Final ownership/perm sweep
echo "-> Final ownership/permission fixes"
sudo chown -R "${TOMCAT_USER}":"${TOMCAT_GROUP}" "${TOMCAT_INSTALL_DIR}"
sudo find "${TOMCAT_INSTALL_DIR}" -type d -exec sudo chmod 755 {} \;
sudo find "${TOMCAT_INSTALL_DIR}" -type f -exec sudo chmod 644 {} \;
# Keep scripts executable
sudo chmod +x "${TOMCAT_INSTALL_DIR}/bin/"*.sh || true

# 8) reload systemd and enable/start service
echo "-> Reloading systemd daemon"
sudo systemctl daemon-reload

echo "-> Enabling tomcat service"
sudo systemctl enable tomcat || true

echo "-> Starting tomcat service (or restarting if already running)"
if systemctl is-active --quiet tomcat; then
  sudo systemctl restart tomcat
else
  sudo systemctl start tomcat
fi

# 12) show service status
echo
echo "=== Tomcat service status ==="
sudo systemctl status tomcat --no-pager || true

echo
echo "=== Done ==="
echo "Access manager at: http://<server-ip>:8080/manager/html  (user: ${TOMCAT_MANAGER_USER})"
echo "If you want to restrict remote access to manager, remove the '.*' from the 'allow' attribute in ${MANAGER_CONTEXT} or configure firewall rules/security groups."
echo "Remember to change the manager password before exposing to the internet."
