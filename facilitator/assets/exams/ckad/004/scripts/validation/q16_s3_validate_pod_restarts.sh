#!/usr/bin/env bash
# Q16.03 - Pod restarts on failure
# Points: 2

NS="liveness-probes"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
RC=$(jp pod live-check "$NS" .status.containerStatuses[0].restartCount)
if [[ -n "$RC" && "$RC" -ge 1 ]]; then
  ok "Pod has restarted due to liveness probe"
else
  fail "Pod has not restarted (restartCount=$RC)"
fi
