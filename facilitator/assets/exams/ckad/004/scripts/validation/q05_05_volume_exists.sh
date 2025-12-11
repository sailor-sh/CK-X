#!/bin/bash
# Q05.05 - Shared volume exists
# Points: 2

VOLUME=$(kubectl get pod init-pod -n q05 -o jsonpath='{.spec.volumes[0].name}' 2>/dev/null)
[[ -n "$VOLUME" ]] && {
  echo "✓ Shared volume exists"
  exit 0
} || {
  echo "✗ No volume found"
  exit 1
}
