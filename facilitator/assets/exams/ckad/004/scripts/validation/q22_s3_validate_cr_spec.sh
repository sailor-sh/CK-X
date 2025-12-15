#!/bin/bash
# Q22.03 - CR spec matches requirements
# Points: 2

# Check if the CR has the expected structure
kubectl get backup my-backup -n crds -o jsonpath='{.spec}' 2>/dev/null | grep -q "backup" && {
  echo "✓ Custom Resource spec is valid"
  exit 0
} || {
  echo "✗ Custom Resource spec does not match requirements"
  exit 1
}