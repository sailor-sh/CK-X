#!/bin/bash
# Q03.01 - Pod multi-box exists
# Points: 2

kubectl get pod multi-box -n q03 >/dev/null 2>&1 && {
  echo "✓ Pod multi-box exists"
  exit 0
} || {
  echo "✗ Pod multi-box not found"
  exit 1
}
