#!/bin/bash
# Q07.03 - PVC test-pvc exists
# Points: 2

kubectl get pvc test-pvc -n q07 >/dev/null 2>&1 && {
  echo "✓ PVC test-pvc exists"
  exit 0
} || {
  echo "✗ PVC test-pvc not found"
  exit 1
}
