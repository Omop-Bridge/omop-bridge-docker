#!/bin/bash
set -e

echo "========================================================"
echo "[WARNING] You are about to destroy the entire OMOP stack and WIPE all database volumes!"
echo "========================================================"
read -p "Are you sure you want to proceed? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "[INFO] Aborted."
    exit 1
fi

echo "[INFO] Tearing down containers and wiping volumes..."
docker compose down -v

echo "[SUCCESS] Stack destroyed and volumes cleared."