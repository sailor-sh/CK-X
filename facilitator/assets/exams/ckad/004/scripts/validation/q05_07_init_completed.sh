#!/bin/bash
# Q05.07 - Init container completed
# Points: 2

STATE=$(kubectl get pod init-pod -n q05 -o jsonpath='{.status.initContainerStatuses[0].state.terminated}' 2>/dev/null)
[[ -n "$STATE" ]] && {
  echo "✓ Init container completed"
  exit 0
} || {
  echo "✗ Init container not completed"
  exit 1
}
