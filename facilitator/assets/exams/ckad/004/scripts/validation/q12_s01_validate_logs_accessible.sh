#!/bin/bash
# Q12.01 - Pod logs accessible
# Points: 2

LOGS=$(kubectl logs logging-pod -n q12 2>/dev/null)
[[ -n "$LOGS" ]] && {
  echo "✓ Pod logs accessible"
  exit 0
} || {
  echo "✗ No logs found"
  exit 1
}
