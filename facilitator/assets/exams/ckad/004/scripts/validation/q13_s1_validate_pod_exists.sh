#!/bin/bash
# Q13.01 - Pod exists
# Points: 2

kubectl get pod env-pod -n security-contexts >/dev/null 2>&1 && {
  echo "✓ Pod env-pod exists"
  exit 0
} || {
  echo "✗ Pod not found"
  exit 1
}
