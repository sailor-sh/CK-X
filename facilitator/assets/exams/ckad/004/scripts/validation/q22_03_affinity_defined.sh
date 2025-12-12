#!/bin/bash
# Q22.03 - Pod affinity defined
# Points: 2

AFFINITY=$(kubectl get pod cache-pod -n q22 -o jsonpath='{.spec.affinity.podAffinity}' 2>/dev/null)
[[ -n "$AFFINITY" ]] && {
  echo "✓ Pod affinity defined"
  exit 0
} || {
  echo "✗ No pod affinity"
  exit 1
}
