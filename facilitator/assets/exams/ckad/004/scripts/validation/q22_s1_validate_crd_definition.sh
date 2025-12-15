#!/bin/bash
# Q22.01 - CRD definition is correct
# Points: 4

# Check if CRD exists with correct specification
kubectl get crd backups.stable.example.com -o jsonpath='{.spec.group}' 2>/dev/null | grep -q "stable.example.com" && {
  echo "✓ CRD backups.stable.example.com has correct group"
  exit 0
} || {
  echo "✗ CRD definition incorrect or missing"
  exit 1
}