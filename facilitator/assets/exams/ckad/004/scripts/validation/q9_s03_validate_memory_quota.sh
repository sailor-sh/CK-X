#!/bin/bash
# Q09.03 - Memory quota set
# Points: 2

MEM=$(kubectl get resourcequota compute-quota -n q09 -o jsonpath='{.spec.hard.requests\.memory}' 2>/dev/null)
[[ -n "$MEM" ]] && {
  echo "✓ Memory quota set: $MEM"
  exit 0
} || {
  echo "✗ No memory quota"
  exit 1
}
