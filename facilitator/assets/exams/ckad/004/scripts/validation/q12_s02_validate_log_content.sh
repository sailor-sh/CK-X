#!/bin/bash
# Q12.02 - Logs contain expected output
# Points: 2

LOGS=$(kubectl logs logging-pod -n q12 2>/dev/null)
[[ "$LOGS" =~ Application ]] && {
  echo "✓ Log output correct"
  exit 0
} || {
  echo "✗ Wrong output"
  exit 1
}
