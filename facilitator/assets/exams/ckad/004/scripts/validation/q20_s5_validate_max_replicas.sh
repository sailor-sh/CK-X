#!/bin/bash
# Q20.05 - Max replicas set
# Points: 2

MAX=$(kubectl get hpa app-hpa -n persistent-storage -o jsonpath='{.spec.maxReplicas}' 2>/dev/null)
[[ -n "$MAX" ]] && {
  echo "✓ Max replicas: $MAX"
  exit 0
} || {
  echo "✗ No max replicas"
  exit 1
}
