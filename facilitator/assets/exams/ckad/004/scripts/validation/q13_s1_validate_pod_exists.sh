#!/bin/bash
# Q13.01 - Pod secure-pod exists
# Points: 2

kubectl get pod secure-pod -n security-contexts >/dev/null 2>&1 && {
  echo "✓ Pod secure-pod exists"
  exit 0
} || {
  echo "✗ Pod secure-pod not found"
  exit 1
}