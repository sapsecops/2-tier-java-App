#!/usr/bin/env bash
# install-devtools.sh
# Installs Git, Amazon Corretto OpenJDK 17, and Maven 3.9.11 on RHEL/Fedora/CentOS

set -euo pipefail
IFS=$'\n\t'

MAVEN_VERSION="3.9.11"
MAVEN_ARCHIVE="apache-maven-${MAVEN_VERSION}-bin.tar.gz"
MAVEN_DOWNLOAD_URL="https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/${MAVEN_ARCHIVE}"
MAVEN_DIR="/opt/apache-maven-${MAVEN_VERSION}"
MAVEN_SYMLINK="/opt/maven"
PROFILE_FILE="/etc/profile.d/maven.sh"

echo "=== Installing Git ==="
sudo yum install -y git || sudo dnf install -y git

echo
echo "=== Installing OpenJDK 17 (Amazon Corretto) ==="
sudo dnf update -y
sudo yum install -y java-17-amazon-corretto-devel || sudo dnf install -y java-17-amazon-corretto-devel

echo
echo "=== Installing Maven ${MAVEN_VERSION} ==="

cd /tmp
if [[ ! -f "${MAVEN_ARCHIVE}" ]]; then
  echo "-> Downloading Maven..."
  sudo wget -q "${MAVEN_DOWNLOAD_URL}"
else
  echo "-> Maven archive already downloaded."
fi

if [[ ! -d "${MAVEN_DIR}" ]]; then
  echo "-> Extracting Maven to /opt..."
  sudo tar -xzf "${MAVEN_ARCHIVE}" -C /opt
else
  echo "-> Maven directory already exists."
fi

if [[ -L "${MAVEN_SYMLINK}" ]]; then
  echo "-> Maven symlink already exists. Updating it."
  sudo rm -f "${MAVEN_SYMLINK}"
fi

echo "-> Creating Maven symlink: ${MAVEN_SYMLINK}"
sudo ln -s "${MAVEN_DIR}" "${MAVEN_SYMLINK}"

echo
echo "=== Configuring Maven Profile ==="

sudo bash -c "cat > ${PROFILE_FILE}" <<EOF
export M2_HOME=${MAVEN_SYMLINK}
export PATH=\${M2_HOME}/bin:\${PATH}
EOF

sudo chmod +x "${PROFILE_FILE}"

echo
echo "-> Reloading profile"
source "${PROFILE_FILE}"

echo
echo "=== Validating Installations ==="

echo "Git version:"
git --version || echo "Git not found"

echo
echo "Java version:"
java -version || echo "Java not found"

echo
echo "Maven version:"
mvn -version || echo "Maven not found"

echo
echo "=== Installation Complete ==="
echo "Git, Java 17, and Maven ${MAVEN_VERSION} are installed."
