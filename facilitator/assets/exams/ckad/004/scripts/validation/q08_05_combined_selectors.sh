#!/bin/bash
# Q08.05 - Label queries accurate
# Points: 2

FILTERED=$(kubectl get pods -n q08 -l env=production,app=web --no-headers 2>/dev/null | wc -l)
[[ $FILTERED -gt 0 ]] && {
  echo "✓ Combined selectors work"
  exit 0
} || {
  echo "✗ No pods match combined selectors"
  exit 1
}
