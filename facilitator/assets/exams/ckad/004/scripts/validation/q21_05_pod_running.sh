#!/bin/bash
# Q21.05 - Pod is running
# Points: 2

PHASE=$(kubectl get pod affinity-pod -n q21 -o jsonpath='{.status.phase}' 2>/dev/null)
[[ "$PHASE" == "Running" ]] && {
  echo "✓ Pod is Running"
  exit 0
} || {
  echo "✗ Pod phase is $PHASE, expected Running"
  exit 1
}
