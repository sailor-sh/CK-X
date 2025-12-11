#!/bin/bash
# Q05.06 - Pod is running
# Points: 2

PHASE=$(kubectl get pod init-pod -n q05 -o jsonpath='{.status.phase}' 2>/dev/null)
[[ "$PHASE" == "Running" ]] && {
  echo "✓ Pod is running"
  exit 0
} || {
  echo "✗ Pod phase is $PHASE, expected Running"
  exit 1
}
