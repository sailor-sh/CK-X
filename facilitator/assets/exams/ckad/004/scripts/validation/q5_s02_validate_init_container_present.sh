#!/bin/bash
# Q05.02 - Init container present
# Points: 2

INIT_COUNT=$(kubectl get pod init-pod -n q05 -o jsonpath='{.spec.initContainers | length}' 2>/dev/null)
[[ "$INIT_COUNT" -gt 0 ]] && {
  echo "✓ Init container present"
  exit 0
} || {
  echo "✗ No init container found"
  exit 1
}
