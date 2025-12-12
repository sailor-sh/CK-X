#!/bin/bash
# Q08.03 - Correct labels applied
# Points: 2

LABELS=$(kubectl get pods -n q08 --show-labels 2>/dev/null | grep env)
[[ -n "$LABELS" ]] && {
  echo "✓ Labels applied"
  exit 0
} || {
  echo "✗ No env labels found"
  exit 1
}
