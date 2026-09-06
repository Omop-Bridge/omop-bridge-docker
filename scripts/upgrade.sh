#!/bin/bash
set -e

echo "========================================================"
echo "[INFO] Upgrading OMOP Bridge stack..."
echo "========================================================"

echo "[Step 1/5] Pulling latest base images..."
docker compose pull

echo "[Step 2/5] Rebuilding container images (ignoring cache)..."
docker compose build --no-cache

echo "[Step 3/5] Restarting services with new builds..."
docker compose up -d

echo "[Step 4/5] Removing previously built unused/dangling images..."
# The -f flag forces the removal without prompting for confirmation
docker image prune -f
