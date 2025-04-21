#!/bin/bash
set -e

# Check if PVCs are created
for i in {0..2}; do
    PVC_NAME="www-web-$i"
    
    # Check if PVC exists
    kubectl get pvc $PVC_NAME -n stateful || {
        echo "PVC $PVC_NAME not found in namespace stateful"
        exit 1
    }
    
    # Check storage class
    STORAGE_CLASS=$(kubectl get pvc $PVC_NAME -n stateful -o jsonpath='{.spec.storageClassName}')
    if [[ "$STORAGE_CLASS" != "cold" ]]; then
        echo "PVC $PVC_NAME has incorrect storage class. Expected cold, got $STORAGE_CLASS"
        exit 1
    fi
    
    # Check storage size
    STORAGE_SIZE=$(kubectl get pvc $PVC_NAME -n stateful -o jsonpath='{.spec.resources.requests.storage}')
    if [[ "$STORAGE_SIZE" != "1Gi" ]]; then
        echo "PVC $PVC_NAME has incorrect storage size. Expected 1Gi, got $STORAGE_SIZE"
        exit 1
    fi
    
    # Check if PVC is bound
    STATUS=$(kubectl get pvc $PVC_NAME -n stateful -o jsonpath='{.status.phase}')
    if [[ "$STATUS" != "Bound" ]]; then
        echo "PVC $PVC_NAME is not bound. Current status: $STATUS"
        exit 1
    fi
done

echo "Storage validation successful"
exit 0 