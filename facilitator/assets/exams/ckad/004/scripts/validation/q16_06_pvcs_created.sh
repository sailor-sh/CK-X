#!/bin/bash
# Q16.06 - PVCs created
# Points: 2

PVC=$(kubectl get pvc -n q16 --no-headers 2>/dev/null | wc -l)
[[ $PVC -gt 0 ]] && {
  echo "✓ PVCs created"
  exit 0
} || {
  echo "✗ No PVCs found"
  exit 1
}
