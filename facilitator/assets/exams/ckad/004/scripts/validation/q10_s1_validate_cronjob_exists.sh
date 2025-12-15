#!/usr/bin/env bash
# Q10.01 - CronJob periodic-task exists
# Points: 2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

NS="cronjobs"
if k_exists cronjob periodic-task "$NS"; then
  ok "CronJob periodic-task exists in $NS"
else
  fail "CronJob periodic-task not found in $NS"
fi
