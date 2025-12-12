#!/bin/bash
# Q22.04 - Affinity targets web tier
# Points: 2

LABEL=$(kubectl get pod cache-pod -n q22 -o jsonpath='{.spec.affinity.podAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.labelSelector}' 2>/dev/null)
[[ -n "$LABEL" ]] && {
  echo "✓ Label selector configured"
  exit 0
} || {
  echo "✗ No label selector"
  exit 1
}
