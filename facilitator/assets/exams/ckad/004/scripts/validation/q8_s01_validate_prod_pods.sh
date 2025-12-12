#!/bin/bash
# Q08.01 - Production pods exist
# Points: 2

PODS=$(kubectl get pods -n q08 -l env=production --no-headers 2>/dev/null | wc -l)
[[ $PODS -gt 0 ]] && {
  echo "✓ Production pods exist"
  exit 0
} || {
  echo "✗ No production pods found"
  exit 1
}
