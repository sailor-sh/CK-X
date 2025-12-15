#!/bin/bash
# Q22.4 - CRD is properly defined
# Points: 2

kubectl get crd backups.stable.example.com 2>/dev/null | grep -q 'backups' && {
  echo "✓ CRD is properly defined"
  exit 0
} || {
  echo "✗ CRD not properly defined"
  exit 1
}
