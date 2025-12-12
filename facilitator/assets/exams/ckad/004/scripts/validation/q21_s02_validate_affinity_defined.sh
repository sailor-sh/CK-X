#!/bin/bash
# Q21.02 - Node affinity defined
# Points: 2

AFFINITY=$(kubectl get pod affinity-pod -n helm-operations -o jsonpath='{.spec.affinity.nodeAffinity}' 2>/dev/null)
[[ -n "$AFFINITY" ]] && {
  echo "✓ Node affinity defined"
  exit 0
} || {
  echo "✗ No node affinity"
  exit 1
}
