#!/bin/bash
# Q09.04 - Pod without limits exists
# Points: 2

kubectl get pod no-limits-pod -n q09 >/dev/null 2>&1 && {
  echo "✓ Pod no-limits-pod exists"
  exit 0
} || {
  echo "✗ Pod not found"
  exit 1
}
