#!/usr/bin/env bash
# run-trivy-scan.sh — Lab helper: run Trivy filesystem and image scans
# Usage: ./run-trivy-scan.sh [fs|image|all]  (default: all)
set -euo pipefail

MODE="${1:-all}"
PROJECT_DIR="/home/ubuntu/vulnerable-app"
REPORT_DIR="/home/ubuntu/reports"
IMAGE_NAME="nginx:1.24"

run_fs_scan() {
  echo "======================================================================"
  echo "  Trivy — Filesystem Scan (vulnerable dependencies + secrets)"
  echo "======================================================================"
  echo ""

  echo "[1/2] Scanning for HIGH/CRITICAL CVEs in dependencies..."
  trivy filesystem \
    --severity HIGH,CRITICAL \
    --format table \
    "${PROJECT_DIR}"

  echo ""
  echo "[2/2] Scanning for hardcoded secrets..."
  trivy filesystem \
    --scanners secret \
    --format table \
    "${PROJECT_DIR}"

  echo ""
  echo "[INFO] Exporting JSON report → ${REPORT_DIR}/trivy-fs-report.json"
  trivy filesystem \
    --scanners vuln,secret \
    --severity HIGH,CRITICAL \
    --format json \
    --output "${REPORT_DIR}/trivy-fs-report.json" \
    "${PROJECT_DIR}"

  echo "[OK]  Report saved: ${REPORT_DIR}/trivy-fs-report.json"
}

run_image_scan() {
  echo "======================================================================"
  echo "  Trivy — Container Image Scan (${IMAGE_NAME})"
  echo "======================================================================"
  echo ""

  echo "[1/2] Scan with HIGH/CRITICAL filter (actionable findings only)..."
  trivy image \
    --severity HIGH,CRITICAL \
    --ignore-unfixed \
    "${IMAGE_NAME}"

  echo ""
  echo "[INFO] Exporting JSON report → ${REPORT_DIR}/trivy-image-report.json"
  trivy image \
    --severity HIGH,CRITICAL \
    --ignore-unfixed \
    --format json \
    --output "${REPORT_DIR}/trivy-image-report.json" \
    "${IMAGE_NAME}"

  echo "[OK]  Report saved: ${REPORT_DIR}/trivy-image-report.json"
}

case "${MODE}" in
  fs)    run_fs_scan ;;
  image) run_image_scan ;;
  all)
    run_fs_scan
    echo ""
    run_image_scan
    ;;
  *)
    echo "Usage: $0 [fs|image|all]"
    exit 1
    ;;
esac

echo ""
echo "Reports are in ${REPORT_DIR}/"
ls -lh "${REPORT_DIR}/"
