#!/usr/bin/env bash
set -euo pipefail

# Start CK-X with a dev override that bind-mounts facilitator assets.
# This ensures changes to labs.json and exam files are visible without a rebuild.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

echo "[dev] Starting with docker-compose.dev.yaml override..."
docker compose -f docker-compose.yaml -f docker-compose.dev.yaml up -d --build

echo "[dev] Done. Visit http://localhost:30080"

