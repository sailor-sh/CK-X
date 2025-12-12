#!/bin/bash
# Q17.03 - CronJob exists
# Points: 2

kubectl get cronjob periodic-task -n q17 >/dev/null 2>&1 && {
  echo "✓ CronJob periodic-task exists"
  exit 0
} || {
  echo "✗ CronJob not found"
  exit 1
}
