#!/bin/bash
# Q16.03 - Pod restarts on failure
# Points: 2

NS="liveness-probes"
RC=$(kubectl get pod live-check -n "$NS" -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null)
if [ -n "$RC" ] && [ "$RC" -ge 1 ] 2>/dev/null; then
  echo "✓ Pod has restarted due to liveness probe"
  exit 0
else
  echo "✗ Pod has not restarted (restartCount=$RC)"
  exit 1
fi

