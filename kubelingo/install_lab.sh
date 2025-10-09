#!/usr/bin/env bash
set -euo pipefail

# Install a generated lab into the running facilitator container and merge labs.json.
#
# Usage:
#   ./kubelingo/install_lab.sh --category ckad --id 003 [--root kubelingo/out]
#
# Options:
#   --category   Lab category (ckad|cka|cks|other)
#   --id         Lab numeric id (e.g., 003)
#   --root       Output root (default: kubelingo/out)
#   --dc         Docker compose command (default: auto-detect)

ROOT="kubelingo/out"
CATEGORY=""
ID=""
DC=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) ROOT="$2"; shift 2 ;;
    --category) CATEGORY="$2"; shift 2 ;;
    --id) ID="$2"; shift 2 ;;
    --dc) DC="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$CATEGORY" || -z "$ID" ]]; then
  echo "Usage: $0 --category <ckad|cka|cks|other> --id <NNN> [--root kubelingo/out] [--dc 'docker compose']" >&2
  exit 2
fi

# Auto-detect docker compose command
if [[ -z "$DC" ]]; then
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    DC="docker compose"
  elif command -v docker-compose >/dev/null 2>&1; then
    DC="docker-compose"
  else
    echo "Error: docker compose/docker-compose not found" >&2
    exit 2
  fi
fi

echo "Using compose command: $DC"

LAB_DIR="$ROOT/facilitator/assets/exams/$CATEGORY/$ID"
CFG="$LAB_DIR/config.json"
if [[ ! -f "$CFG" ]]; then
  echo "Error: $CFG not found. Generate the lab first." >&2
  exit 2
fi

# Ensure the stack is up
$DC up -d 1>/dev/null

# Find facilitator container
FID=$($DC ps -q facilitator)
if [[ -z "$FID" ]]; then
  FID=$(docker ps --filter "name=facilitator" -q | head -n1)
fi
if [[ -z "$FID" ]]; then
  echo "Error: facilitator container not found" >&2
  exit 2
fi
echo "Facilitator container: $FID"

# Copy lab into container
docker exec "$FID" mkdir -p "/usr/src/app/assets/exams/$CATEGORY"
docker cp "$LAB_DIR" "$FID":/usr/src/app/assets/exams/$CATEGORY/

# Merge labs.json
docker cp "$FID":/usr/src/app/assets/exams/labs.json "$ROOT/labs.base.json"
python3 "$(dirname "$0")/merge_labs.py" --root "$ROOT" --lab-category "$CATEGORY" --lab-id "$ID" --existing "$ROOT/labs.base.json" --out "$ROOT/labs.merged.json"
docker cp "$ROOT/labs.merged.json" "$FID":/usr/src/app/assets/exams/labs.json

# Restart facilitator to repack assets
$DC restart facilitator 1>/dev/null
echo "Installed lab $CATEGORY-$ID and restarted facilitator. Check the web UI."

