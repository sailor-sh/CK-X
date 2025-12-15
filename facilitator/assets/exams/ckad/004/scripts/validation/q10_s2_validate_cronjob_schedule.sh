#!/bin/bash
# Q10.02 - CronJob schedule */1 * * * *
# Points: 3

NS="cronjobs"
SCH=$(kubectl get cronjob periodic-task -n "$NS" -o jsonpath='{.spec.schedule}' 2>/dev/null)
if [ "$SCH" = "*/1 * * * *" ]; then
  echo "✓ CronJob schedule is */1 * * * *"
  exit 0
else
  echo "✗ CronJob schedule is '$SCH', expected '*/1 * * * *'"
  exit 1
fi

