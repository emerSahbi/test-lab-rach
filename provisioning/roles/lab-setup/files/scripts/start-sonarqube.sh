#!/usr/bin/env bash
# start-sonarqube.sh — Lab helper: start SonarQube Community Edition
# Usage: ./start-sonarqube.sh
set -euo pipefail

CONTAINER_NAME="sonarqube"
PORT=9000

# Check if already running
if docker ps --filter "name=${CONTAINER_NAME}" --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "[INFO] SonarQube is already running → http://localhost:${PORT}"
  exit 0
fi

echo "[INFO] Starting SonarQube Community Edition on port ${PORT}..."
docker run -d \
  --name "${CONTAINER_NAME}" \
  -p "${PORT}:9000" \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  sonarqube:community

echo ""
echo "[INFO] Waiting for SonarQube to become ready (this takes ~60 seconds)..."

RETRIES=30
for i in $(seq 1 ${RETRIES}); do
  STATUS=$(curl -s "http://localhost:${PORT}/api/system/status" 2>/dev/null | grep -o '"status":"[^"]*"' | cut -d'"' -f4 || true)
  if [ "${STATUS}" = "UP" ]; then
    echo ""
    echo "============================================================"
    echo "  SonarQube is UP!"
    echo "  URL      : http://$(hostname -I | awk '{print $1}'):${PORT}"
    echo "  Username : admin"
    echo "  Password : admin  (you will be asked to change it)"
    echo "============================================================"
    exit 0
  fi
  printf "  ... attempt %d/%d (status: %s)\r" "${i}" "${RETRIES}" "${STATUS:-waiting}"
  sleep 5
done

echo "[ERROR] SonarQube did not become ready in time."
echo "        Check logs: docker logs ${CONTAINER_NAME}"
exit 1
