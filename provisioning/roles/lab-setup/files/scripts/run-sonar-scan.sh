#!/usr/bin/env bash
# run-sonar-scan.sh — Lab helper: run sonar-scanner against vulnerable-app
# Usage: ./run-sonar-scan.sh <SONAR_TOKEN>
set -euo pipefail

TOKEN="${1:-}"

if [ -z "${TOKEN}" ]; then
  echo "Usage: $0 <SONAR_TOKEN>"
  echo ""
  echo "Get a token from: SonarQube → My Account → Security → Generate Token"
  exit 1
fi

SONAR_HOST="http://localhost:9000"
PROJECT_DIR="/home/ubuntu/vulnerable-app"

# Detect SonarQube host IP (in case localhost doesn't resolve from inside Docker)
HOST_IP=$(hostname -I | awk '{print $1}')

echo "[INFO] Running SonarScanner against ${PROJECT_DIR}"
echo "[INFO] SonarQube host: ${SONAR_HOST} (also reachable at http://${HOST_IP}:9000)"
echo ""

docker run --rm \
  --add-host="host.docker.internal:${HOST_IP}" \
  -e SONAR_HOST_URL="http://host.docker.internal:9000" \
  -e SONAR_TOKEN="${TOKEN}" \
  -v "${PROJECT_DIR}:/usr/src" \
  sonarsource/sonar-scanner-cli

echo ""
echo "[INFO] Scan complete. Open SonarQube at http://${HOST_IP}:9000 to view results."
