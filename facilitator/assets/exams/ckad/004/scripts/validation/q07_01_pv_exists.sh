#!/bin/bash
# Q07.01 - PersistentVolume test-pv exists
# Points: 2

kubectl get pv test-pv >/dev/null 2>&1 && {
  echo "✓ PersistentVolume test-pv exists"
  exit 0
} || {
  echo "✗ PersistentVolume test-pv not found"
  exit 1
}
