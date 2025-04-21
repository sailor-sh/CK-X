#!/bin/bash
set -e

# Check if PVC exists
kubectl get pvc manual-pvc -n manual-storage || {
    echo "PVC manual-pvc not found in namespace manual-storage"
    exit 1
}

# Validate storage size
STORAGE_SIZE=$(kubectl get pvc manual-pvc -n manual-storage -o jsonpath='{.spec.resources.requests.storage}')
if [[ "$STORAGE_SIZE" != "1Gi" ]]; then
    echo "Incorrect storage size. Expected '1Gi', got '$STORAGE_SIZE'"
    exit 1
fi

# Validate access mode
ACCESS_MODE=$(kubectl get pvc manual-pvc -n manual-storage -o jsonpath='{.spec.accessModes[0]}')
if [[ "$ACCESS_MODE" != "ReadWriteOnce" ]]; then
    echo "Incorrect access mode. Expected 'ReadWriteOnce', got '$ACCESS_MODE'"
    exit 1
fi

# Check if PVC is bound
PVC_STATUS=$(kubectl get pvc manual-pvc -n manual-storage -o jsonpath='{.status.phase}')
if [[ "$PVC_STATUS" != "Bound" ]]; then
    echo "PVC is not bound. Current status: $PVC_STATUS"
    exit 1
fi

# Verify it's bound to the correct PV
BOUND_PV=$(kubectl get pvc manual-pvc -n manual-storage -o jsonpath='{.spec.volumeName}')
if [[ "$BOUND_PV" != "manual-pv" ]]; then
    echo "PVC is bound to wrong PV. Expected 'manual-pv', got '$BOUND_PV'"
    exit 1
fi

echo "PVC validation successful"
exit 0 