#!/bin/bash
# Q07.02 - PV has 1Gi storage
# Points: 2

STORAGE=$(kubectl get pv test-pv -o jsonpath='{.spec.capacity.storage}' 2>/dev/null)
[[ "$STORAGE" == "1Gi" ]] && {
  echo "✓ PV storage is 1Gi"
  exit 0
} || {
  echo "✗ PV storage is $STORAGE, expected 1Gi"
  exit 1
}
