#!/bin/bash
# Q20.04 - Min replicas set
# Points: 2

MIN=$(kubectl get hpa app-hpa -n persistent-storage -o jsonpath='{.spec.minReplicas}' 2>/dev/null)
[[ -n "$MIN" ]] && {
  echo "✓ Min replicas: $MIN"
  exit 0
} || {
  echo "✗ No min replicas"
  exit 1
}
