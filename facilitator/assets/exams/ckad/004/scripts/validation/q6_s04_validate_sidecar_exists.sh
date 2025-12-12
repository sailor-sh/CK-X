#!/bin/bash
# Q06.04 - Sidecar container exists
# Points: 2

SIDECAR=$(kubectl get pod multi-container -n q06 -o jsonpath='{.spec.containers[1].name}' 2>/dev/null)
[[ -n "$SIDECAR" ]] && {
  echo "✓ Sidecar container exists"
  exit 0
} || {
  echo "✗ No sidecar container"
  exit 1
}
