#!/bin/bash
# Q07.04 - PVC bound to PV
# Points: 2

PHASE=$(kubectl get pvc test-pvc -n q07 -o jsonpath='{.status.phase}' 2>/dev/null)
[[ "$PHASE" == "Bound" ]] && {
  echo "✓ PVC is Bound"
  exit 0
} || {
  echo "✗ PVC phase is $PHASE, expected Bound"
  exit 1
}
