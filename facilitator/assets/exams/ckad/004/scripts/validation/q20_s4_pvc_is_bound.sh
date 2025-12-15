#!/bin/bash
# Q20.4 - PVC is bound
# Points: 2

kubectl get pvc data-pvc -n persistent-storage -o jsonpath='{.status.phase}' 2>/dev/null | grep -q 'Bound' && {
  echo "✓ PVC is bound"
  exit 0
} || {
  echo "✗ PVC not bound"
  exit 1
}
