#!/bin/bash
# Q04.06 - Log file contains expected content
# Points: 2

LOG_CONTENT=$(kubectl exec logger-pod -n sidecar-logging -c app -- cat /var/log/app.log 2>/dev/null | grep "logging info" | wc -l)
[[ $LOG_CONTENT -gt 0 ]] && {
  echo "✓ Log file contains expected content"
  exit 0
} || {
  echo "✗ Log file missing expected content"
  exit 1
}
