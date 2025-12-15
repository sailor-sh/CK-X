#!/bin/bash
# Q10.04 - CronJob creates completed jobs
# Points: 2

COMPLETED=$(kubectl get jobs -n cronjobs -l job-name=periodic-task --no-headers 2>/dev/null | grep -c "1/1")
[[ $COMPLETED -gt 0 ]] && {
  echo "✓ CronJob creates completed jobs"
  exit 0
} || {
  echo "✗ No completed jobs found"
  exit 1
}
