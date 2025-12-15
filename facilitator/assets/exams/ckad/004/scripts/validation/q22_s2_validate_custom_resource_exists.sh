#!/bin/bash
# Q22.02 - Custom Resource instance my-backup exists
# Points: 4

NS="crds"
kubectl get backup my-backup -n "$NS" >/dev/null 2>&1 && {
  echo "✓ Custom Resource my-backup exists in $NS"
  exit 0
} || {
  echo "✗ Custom Resource my-backup not found in $NS"
  exit 1
}

