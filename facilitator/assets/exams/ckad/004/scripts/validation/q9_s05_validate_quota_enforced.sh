#!/bin/bash
# Q09.05 - Quota enforced
# Points: 2

HARD=$(kubectl get resourcequota compute-quota -n q09 -o jsonpath='{.status.hard.requests\.cpu}' 2>/dev/null)
[[ -n "$HARD" ]] && {
  echo "✓ Quota enforced"
  exit 0
} || {
  echo "✗ Quota not enforced"
  exit 1
}
