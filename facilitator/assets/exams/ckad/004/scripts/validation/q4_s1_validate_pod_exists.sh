#!/bin/bash
# Q04.01 - Pod logger-pod exists
# Points: 2

kubectl get pod logger-pod -n logging >/dev/null 2>&1 && {
  echo "✓ Pod logger-pod exists"
  exit 0
} || {
  echo "✗ Pod logger-pod not found"
  exit 1
}