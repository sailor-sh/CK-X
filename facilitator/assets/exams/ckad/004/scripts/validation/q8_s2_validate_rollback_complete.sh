#!/usr/bin/env bash
# Q08.02 - Rollout is complete
# Points: 3

NS="rollbacks"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
if kubectl rollout status deploy/web-deploy -n "$NS" >/dev/null 2>&1; then
  ok "Rollout is complete"
else
  fail "Rollout not complete"
fi
