#!/bin/bash
# Q17.04 - CronJob schedule valid
# Points: 2

SCHEDULE=$(kubectl get cronjob periodic-task -n q17 -o jsonpath='{.spec.schedule}' 2>/dev/null)
[[ -n "$SCHEDULE" ]] && {
  echo "✓ Schedule: $SCHEDULE"
  exit 0
} || {
  echo "✗ No schedule"
  exit 1
}
