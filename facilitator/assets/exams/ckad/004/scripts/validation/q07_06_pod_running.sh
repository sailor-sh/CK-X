#!/bin/bash
# Q07.06 - Pod running
# Points: 2

PHASE=$(kubectl get pod volume-pod -n q07 -o jsonpath='{.status.phase}' 2>/dev/null)
[[ "$PHASE" == "Running" ]] && {
  echo "✓ Pod is Running"
  exit 0
} || {
  echo "✗ Pod phase is $PHASE, expected Running"
  exit 1
}
