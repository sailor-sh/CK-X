#!/bin/bash
# Q12.03 - Pod is running
# Points: 2

PHASE=$(kubectl get pod logging-pod -n secrets-volume -o jsonpath='{.status.phase}' 2>/dev/null)
[[ "$PHASE" == "Running" ]] && {
  echo "✓ Pod running"
  exit 0
} || {
  echo "✗ Pod phase is $PHASE, expected Running"
  exit 1
}
