#!/bin/bash
set -e

echo "========================================================"
echo "[INFO] Building and starting OMOP Bridge stack..."
echo "========================================================"

# Step 1: Build containers with clear visibility
echo "[Step 1/3] Building container images..."
docker compose build --progress=plain

# Step 2: Start services in detached mode
echo "[Step 2/3] Initializing and starting services..."
docker compose up -d

# Step 3: Stream database logs to monitor initialization progress
echo "[Step 3/3] Tailing database container logs to monitor setup..."
echo "--------------------------------------------------------"
echo "Tip: Press Ctrl+C at any time to detach from logs (services will keep running)."
echo "--------------------------------------------------------"

docker logs -f omop-bridge-db