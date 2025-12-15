#!/usr/bin/env bash
# Q09.01 - Job batch-job exists
# Points: 2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

NS="batch-jobs"
if k_exists job batch-job "$NS"; then
  ok "Job batch-job exists in $NS"
else
  fail "Job batch-job not found in $NS"
fi
