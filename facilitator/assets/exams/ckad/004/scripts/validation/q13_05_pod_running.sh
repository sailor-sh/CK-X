#!/bin/bash
# Q13.05 - Pod is running
# Points: 2

PHASE=$(kubectl get pod env-pod -n q13 -o jsonpath='{.status.phase}' 2>/dev/null)
[[ "$PHASE" == "Running" ]] && {
  echo "✓ Pod running"
  exit 0
} || {
  echo "✗ Pod phase is $PHASE, expected Running"
  exit 1
}
