#!/bin/bash

# Stop the script if any command fails (optional)
set -e

echo "Starting execution..."

./01-install_tools.sh
echo "Finished script1.sh"

./02-tomcat.sh
echo "Finished script2.sh"

./03-app_deploy.sh
echo "Finished script3.sh"

echo "All scripts executed successfully!"
