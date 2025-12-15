#!/usr/bin/env bash
# Q10.02 - CronJob schedule */1 * * * *
# Points: 3

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

NS="cronjobs"
SCH=$(jp cronjob periodic-task "$NS" .spec.schedule)
expect_equals "$SCH" "*/1 * * * *" \
  "CronJob schedule is */1 * * * *" \
  "CronJob schedule is '$SCH', expected '*/1 * * * *'"
