#!/bin/bash
# Q01.04 - Pod is in Running state
# Points: 2

PHASE=$(kubectl get pod web-core -n ckad-ns-a -o jsonpath='{.status.phase}' 2>/dev/null)
[[ "$PHASE" == "Running" ]] && {
  echo "✓ Pod is in Running state"
  exit 0
} || {
  echo "✗ Pod phase is $PHASE, expected Running"
  exit 1
}
