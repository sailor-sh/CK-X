#!/usr/bin/env bash
set -euo pipefail

# CK-X: Developer fresh start for Exam 3 (ckad-003)
#
# What this does:
# 1) Fully cleans the current compose stack (containers, images, volumes)
# 2) Rebuilds and starts the simulator stack with local assets
# 3) Waits for the facilitator to be up and packages exam assets
# 4) Verifies the labs endpoint includes ckad-003
# 5) Prints next steps to start the exam in the UI
#
# Usage:
#   ./scripts/dev_fresh_exam3.sh
#
# Notes:
# - This script is destructive to CK-X containers/images/volumes in this project.
# - If you only need to restart without pruning, use: ./scripts/setup_exam3_local.sh

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "==============================================="
echo "CK-X: Fresh developer start for Exam 3 (ckad-003)"
echo "==============================================="
echo "This will remove CK-X containers/images/volumes and rebuild."

# Step 1: Full clean slate
echo "\n[1/5] Stopping and removing containers + volumes + images..."
docker compose down --volumes --remove-orphans --rmi all || true
docker system prune -af || true
docker volume prune -f || true

# Step 2: Rebuild and start
echo "\n[2/5] Rebuilding and starting services with local assets..."
chmod +x scripts/setup_exam3_local.sh || true
./scripts/setup_exam3_local.sh

# Step 3: Wait for facilitator to be healthy
echo "\n[3/5] Waiting for facilitator to be healthy..."
attempt=0
until docker compose ps facilitator | grep -q healthy; do
  attempt=$((attempt+1))
  if [ "$attempt" -ge 60 ]; then
    echo "Timeout waiting for facilitator health. Check 'docker compose logs facilitator'." >&2
    exit 1
  fi
  sleep 2
done
echo "Facilitator is healthy."

# Step 4: Verify labs list includes ckad-003
echo "\n[4/5] Verifying labs endpoint includes ckad-003..."
attempt=0
ok=false
while [ $attempt -lt 30 ]; do
  attempt=$((attempt+1))
  body=$(curl -sf http://localhost:30080/facilitator/api/v1/assessments/ || true)
  if echo "$body" | grep -q 'ckad-003'; then
    ok=true
    break
  fi
  sleep 2
done

if [ "$ok" != true ]; then
  echo "Labs endpoint did not include ckad-003 yet. You can still try in the UI;"
  echo "otherwise check logs: 'docker compose logs facilitator'" >&2
else
  echo "ckad-003 found in labs list."
fi

# Step 5: Print next steps
echo "\n[5/5] Ready. Open the simulator and start Exam 3:"
echo "  URL: http://localhost:30080"
echo "  In the UI: Start Exam → CKAD Comprehensive Lab - 3"
echo "\nQuick checks (in SSH terminal panel):"
echo "  kubectl cluster-info"
echo "  kubectl get nodes"

# Attempt to open browser on macOS/Linux if possible
if command -v open >/dev/null 2>&1; then
  open http://localhost:30080 || true
elif command -v xdg-open >/dev/null 2>&1; then
  xdg-open http://localhost:30080 || true
fi

echo "\nDone."

