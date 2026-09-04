#!/bin/bash
set -e

echo "========================================================"
echo "[INFO] Stopping OMOP Bridge stack..."
echo "========================================================"

docker compose stop

echo "[INFO] Containers stopped successfully."