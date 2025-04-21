#!/bin/bash
set -e

# Check if PVC exists
kubectl get pvc data-pvc -n storage-task || {
    echo "PVC data-pvc not found in namespace storage-task"
    exit 1
}

# Validate storage class
STORAGE_CLASS=$(kubectl get pvc data-pvc -n storage-task -o jsonpath='{.spec.storageClassName}')
if [[ "$STORAGE_CLASS" != "standard" ]]; then
    echo "Incorrect storage class. Expected 'standard', got '$STORAGE_CLASS'"
    exit 1
fi

# Validate access mode
ACCESS_MODE=$(kubectl get pvc data-pvc -n storage-task -o jsonpath='{.spec.accessModes[0]}')
if [[ "$ACCESS_MODE" != "ReadWriteOnce" ]]; then
    echo "Incorrect access mode. Expected 'ReadWriteOnce', got '$ACCESS_MODE'"
    exit 1
fi

# Validate storage size
STORAGE_SIZE=$(kubectl get pvc data-pvc -n storage-task -o jsonpath='{.spec.resources.requests.storage}')
if [[ "$STORAGE_SIZE" != "2Gi" ]]; then
    echo "Incorrect storage size. Expected '2Gi', got '$STORAGE_SIZE'"
    exit 1
fi

echo "PVC validation successful"
exit 0 