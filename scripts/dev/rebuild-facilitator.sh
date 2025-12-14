#!/usr/bin/env bash
set -euo pipefail

# Force-rebuild the facilitator image and restart just that service.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

echo "[dev] Rebuilding facilitator (no-cache) ..."
docker compose build --no-cache facilitator
echo "[dev] Restarting facilitator ..."
docker compose up -d facilitator

echo "[dev] Checking labs endpoint ..."
curl -sf http://localhost:30080/facilitator/api/v1/assements | jq '.[].id' || true

