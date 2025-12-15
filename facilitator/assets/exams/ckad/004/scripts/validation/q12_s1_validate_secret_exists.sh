#!/bin/bash
# Q12.01 - Secret app-secret exists
# Points: 2

NS="secrets-volume"
kubectl get secret app-secret -n "$NS" >/dev/null 2>&1 && {
  echo "✓ Secret app-secret exists in $NS"
  exit 0
} || {
  echo "✗ Secret app-secret not found in $NS"
  exit 1
}

