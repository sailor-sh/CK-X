#!/usr/bin/env bash
# Q10.03 - CronJob creates Jobs
# Points: 3

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

NS="cronjobs"
COUNT=$(kubectl get jobs -n "$NS" -o jsonpath='{range .items[*]}{.metadata.ownerReferences[0].kind}:{.metadata.ownerReferences[0].name}{"\n"}{end}' 2>/dev/null | grep -c "CronJob:periodic-task")
if [[ "$COUNT" -ge 1 ]]; then
  ok "At least one Job created by CronJob"
else
  fail "No Jobs found created by CronJob periodic-task"
fi
