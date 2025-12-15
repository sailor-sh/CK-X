#!/bin/bash
# Q05.05 - Label selectors work correctly
# Points: 2

SELECTED=$(kubectl get pods -n labels-selectors -l env=production --no-headers 2>/dev/null | wc -l)
[[ $SELECTED -eq 1 ]] && {
  echo "✓ Label selector works correctly"
  exit 0
} || {
  echo "✗ Label selector issue (found $SELECTED pods, expected 1)"
  exit 1
}
