#!/usr/bin/env bash
# Q07.03 - Rollout history present
# Points: 4

NS="rolling-updates"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
OUT=$(kubectl rollout history deploy/web-deploy -n "$NS" 2>/dev/null | tail -n +2)
expect_nonempty "$OUT" \
  "Rollout history recorded" \
  "No rollout history found"
