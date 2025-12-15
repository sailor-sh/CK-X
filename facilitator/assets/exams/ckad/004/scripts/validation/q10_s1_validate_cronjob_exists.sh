#!/bin/bash
# Q10.01 - CronJob periodic-task exists
# Points: 2

NS="cronjobs"
kubectl get cronjob periodic-task -n "$NS" >/dev/null 2>&1 && {
  echo "✓ CronJob periodic-task exists in $NS"
  exit 0
} || {
  echo "✗ CronJob periodic-task not found in $NS"
  exit 1
}

