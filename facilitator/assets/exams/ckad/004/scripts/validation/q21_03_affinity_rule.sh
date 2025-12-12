#!/bin/bash
# Q21.03 - Affinity rule correct
# Points: 2

RULE=$(kubectl get pod affinity-pod -n q21 -o jsonpath='{.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution}' 2>/dev/null)
[[ -n "$RULE" ]] && {
  echo "✓ Affinity rule configured"
  exit 0
} || {
  echo "✗ No affinity rule"
  exit 1
}
