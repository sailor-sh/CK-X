#!/bin/bash
# Q09.02 - CPU quota set
# Points: 2

CPU=$(kubectl get resourcequota compute-quota -n q09 -o jsonpath='{.spec.hard.requests\.cpu}' 2>/dev/null)
[[ -n "$CPU" ]] && {
  echo "✓ CPU quota set: $CPU"
  exit 0
} || {
  echo "✗ No CPU quota"
  exit 1
}
