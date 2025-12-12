#!/bin/bash
# Q06.05 - Shared volume mounted
# Points: 2

VOLUME=$(kubectl get pod multi-container -n q06 -o jsonpath='{.spec.volumes[0].name}' 2>/dev/null)
[[ -n "$VOLUME" ]] && {
  echo "✓ Volume exists: $VOLUME"
  exit 0
} || {
  echo "✗ No volume found"
  exit 1
}
