#!/bin/bash
# Q08.02 - Development pods exist
# Points: 2

PODS=$(kubectl get pods -n q08 -l env=development --no-headers 2>/dev/null | wc -l)
[[ $PODS -gt 0 ]] && {
  echo "✓ Development pods exist"
  exit 0
} || {
  echo "✗ No development pods found"
  exit 1
}
