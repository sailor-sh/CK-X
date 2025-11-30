#!/usr/bin/env bash
set -euo pipefail

# Local developer setup for CK-X with CKAD exam 3 assets (ckad-003)

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "Preparing docker-compose override to build local facilitator with exam3 assets..."
if [ ! -f docker-compose.override.yaml ]; then
  cp kubelingo/docker-compose.override.yaml docker-compose.override.yaml
  echo "Created docker-compose.override.yaml"
else
  echo "docker-compose.override.yaml already present"
fi

echo "Starting/rebuilding services..."
docker compose up -d --build --remove-orphans

echo "Waiting for facilitator to package assets..."
sleep 5

echo "Done. Access UI at http://localhost:30080/ and select CKAD Comprehensive Lab - 3"
