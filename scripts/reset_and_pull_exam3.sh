#!/usr/bin/env bash
set -euo pipefail

# Reset CK-X stack and pull images fresh
# - Stops containers, removes named volumes, and removes service images
# - Pulls images again (respecting docker-compose.override.yaml if present)
# - Brings the stack back up
#
# Usage:
#   ./scripts/reset_and_pull_exam3.sh
#
# Notes:
# - Runs in the repo root (where docker-compose.yaml lives)
# - If docker-compose.override.yaml exists (e.g., pointing to je01/…:exam3-vX), it will be used
# - Removes volumes (course-data, kube-config) to ensure a clean exam state

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"

if [[ ! -f docker-compose.yaml ]]; then
  echo "docker-compose.yaml not found; run from repo root." >&2
  exit 1
fi

COMPOSE=(docker compose -f docker-compose.yaml)
if [[ -f docker-compose.override.yaml ]]; then
  COMPOSE+=( -f docker-compose.override.yaml )
fi

echo "[1/5] Taking stack down (remove orphans + volumes)…"
"${COMPOSE[@]}" down -v --remove-orphans || true

echo "[2/5] Enumerating service images from compose config…"
IMAGES=$("${COMPOSE[@]}" config | awk '/image:/ {print $2}' | sort -u || true)
if [[ -n "${IMAGES}" ]]; then
  echo "Found images:"; echo "$IMAGES" | sed 's/^/  - /'
else
  echo "No explicit images found in compose config (services may be build-only)."
fi

echo "[3/5] Removing images to force fresh pulls…"
if [[ -n "${IMAGES}" ]]; then
  while read -r img; do
    [[ -z "$img" ]] && continue
    echo "Removing $img"
    docker image rm -f "$img" >/dev/null 2>&1 || true
  done <<< "$IMAGES"
else
  echo "Skipping image removal."
fi

echo "[4/5] Pulling images fresh…"
"${COMPOSE[@]}" pull

echo "[5/5] Starting stack…"
"${COMPOSE[@]}" up -d

echo "\nStack status:" 
"${COMPOSE[@]}" ps
echo "\nDone. Open http://localhost:30080 and select CKAD Comprehensive Lab - 3."

