#!/bin/bash
# Q22.02 - Cache pod exists
# Points: 2

kubectl get pod cache-pod -n crds >/dev/null 2>&1 && {
  echo "✓ Pod cache-pod exists"
  exit 0
} || {
  echo "✗ Pod not found"
  exit 1
}
