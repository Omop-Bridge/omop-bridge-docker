#!/bin/bash
set -e

echo "Loading all OMOP Bridge infrastructure and application images..."
cd dockerImage

# Custom OMOP Bridge Images
[ -f "OMOPBridge_DB.tar.gz" ] && gunzip -c OMOPBridge_DB.tar.gz | docker load
[ -f "OMOPBridge_Backend.tar.gz" ] && gunzip -c OMOPBridge_Backend.tar.gz | docker load
[ -f "OMOPBridge_RRunner.tar.gz" ] && gunzip -c OMOPBridge_RRunner.tar.gz | docker load
[ -f "OMOPBridge_Frontend.tar.gz" ] && gunzip -c OMOPBridge_Frontend.tar.gz | docker load
[ -f "OMOPBridge_WebAPI.tar.gz" ] && gunzip -c OMOPBridge_WebAPI.tar.gz | docker load

# Supporting Stack & Base Images
[ -f "Postgres_Base.tar.gz" ] && gunzip -c Postgres_Base.tar.gz | docker load
[ -f "nginx_alpine.tar.gz" ] && gunzip -c nginx_alpine.tar.gz | docker load
[ -f "atlas3_frontend.tar.gz" ] && gunzip -c atlas3_frontend.tar.gz | docker load
[ -f "dbgate.tar.gz" ] && gunzip -c dbgate.tar.gz | docker load
[ -f "loki.tar.gz" ] && gunzip -c loki.tar.gz | docker load
[ -f "promtail.tar.gz" ] && gunzip -c promtail.tar.gz | docker load
[ -f "prometheus.tar.gz" ] && gunzip -c prometheus.tar.gz | docker load
[ -f "grafana.tar.gz" ] && gunzip -c grafana.tar.gz | docker load

cd ..

echo "Checking Docker Compose version..."
docker_version=$(docker --version | awk '{print $3}' | sed 's/,//')
major_version=$(echo "$docker_version" | cut -d'.' -f1)

if [[ "$major_version" -ge 20 ]]; then
    compose_command="docker compose"
else
    compose_command="docker-compose"
fi

echo "Starting full OMOP Bridge stack using: $compose_command"
$compose_command up -d