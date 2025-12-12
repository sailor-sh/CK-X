#!/bin/bash
# Q05.01 - Pod init-pod exists
# Points: 2

kubectl get pod init-pod -n q05 >/dev/null 2>&1 && {
  echo "✓ Pod init-pod exists"
  exit 0
} || {
  echo "✗ Pod init-pod not found"
  exit 1
}
