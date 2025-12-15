#!/bin/bash
# Q10.03 - CronJob creates Jobs
# Points: 3

NS="cronjobs"
COUNT=$(kubectl get jobs -n "$NS" -o jsonpath='{range .items[*]}{.metadata.ownerReferences[0].kind}:{.metadata.ownerReferences[0].name}{"\n"}{end}' 2>/dev/null | grep -c "CronJob:periodic-task")
if [ "$COUNT" -ge 1 ]; then
  echo "✓ At least one Job created by CronJob"
  exit 0
else
  echo "✗ No Jobs found created by CronJob periodic-task"
  exit 1
fi

