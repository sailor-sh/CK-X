#!/bin/bash
# Q10.05 - Job logs contain expected output
# Points: 2

JOB_NAME=$(kubectl get jobs -n cronjobs -l job-name=periodic-task --no-headers 2>/dev/null | head -1 | awk '{print $1}')
if [[ -n "$JOB_NAME" ]]; then
  LOG_CONTENT=$(kubectl logs job/$JOB_NAME -n cronjobs 2>/dev/null | grep -c "date\|Date")
  [[ $LOG_CONTENT -gt 0 ]] && {
    echo "✓ Job logs contain expected output"
    exit 0
  }
fi

echo "✗ Job logs missing expected output"
exit 1
