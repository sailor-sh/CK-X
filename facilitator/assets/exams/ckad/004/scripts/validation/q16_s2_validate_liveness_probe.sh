#!/bin/bash
# Q16.02 - Liveness probe configured correctly
# Points: 4

NS="liveness-probes"
CMD=$(kubectl get pod live-check -n "$NS" -o jsonpath='{.spec.containers[0].livenessProbe.exec.command[0]}' 2>/dev/null)
if [ "$CMD" = "cat" ]; then
  echo "✓ Liveness probe exec command configured"
  exit 0
else
  echo "✗ Liveness probe not configured as expected"
  exit 1
fi

