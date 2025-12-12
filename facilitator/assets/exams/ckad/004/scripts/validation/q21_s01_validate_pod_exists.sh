#!/bin/bash
# Q21.01 - Pod exists
# Points: 2

kubectl get pod affinity-pod -n q21 >/dev/null 2>&1 && {
  echo "✓ Pod affinity-pod exists"
  exit 0
} || {
  echo "✗ Pod not found"
  exit 1
}
