#!/bin/bash
set -e

echo "========================================================"
echo "[INFO] Upgrading OMOP Bridge stack..."
echo "========================================================"

echo "[Step 1/3] Pulling latest base images..."
docker compose pull

echo "[Step 2/3] Rebuilding container images and restarting services..."
docker compose up --build -d

echo "[Step 3/3] Tailing database logs to monitor state..."
echo "--------------------------------------------------------"
echo "Tip: Press Ctrl+C at any time to exit logs (services will keep running)."
echo "--------------------------------------------------------"

docker logs -f omop-bridge-db