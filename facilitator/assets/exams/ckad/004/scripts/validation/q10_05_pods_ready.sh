#!/bin/bash
# Q10.05 - Pods are ready
# Points: 2

READY=$(kubectl get deployment no-readiness -n q10 -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
[[ -n "$READY" ]] && {
  echo "✓ Pods ready: $READY"
  exit 0
} || {
  echo "✗ No ready replicas"
  exit 1
}
