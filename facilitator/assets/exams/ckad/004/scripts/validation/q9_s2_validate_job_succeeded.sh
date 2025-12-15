#!/usr/bin/env bash
# Q09.02 - Job succeeded
# Points: 3

NS="batch-jobs"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
SUC=$(jp job batch-job "$NS" .status.succeeded)
if [[ -n "$SUC" && "$SUC" -ge 1 ]]; then
  ok "Job batch-job succeeded"
else
  fail "Job batch-job has not succeeded"
fi
