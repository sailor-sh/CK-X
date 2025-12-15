#!/bin/bash
# Q20.01 - PVC data-pvc exists and Bound
# Points: 3

NS="persistent-storage"
PHASE=$(kubectl get pvc data-pvc -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PHASE" = "Bound" ]; then
  echo "✓ PVC data-pvc is Bound"
  exit 0
else
  echo "✗ PVC data-pvc phase is '$PHASE', expected 'Bound'"
  exit 1
fi

