#!/usr/bin/env bash
# Q09.03 - Logs contain output
# Points: 3

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

NS="batch-jobs"
POD=$(first_pod_name_by_label "$NS" 'job-name=batch-job')
if [[ -z "$POD" ]]; then
  fail "No pod found for job batch-job"
fi
LOGS=$(kubectl logs "$POD" -n "$NS" 2>/dev/null)
expect_contains "$LOGS" "Task Complete" \
  "Job logs contain expected output" \
  "Job logs do not contain expected output"
