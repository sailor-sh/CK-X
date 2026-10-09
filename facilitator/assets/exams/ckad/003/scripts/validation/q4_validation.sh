#!/bin/bash
set -e

# Validation for Question 4: Persistent Volume Claims
echo "Validating Persistent Volume Claims scenario..."

# Check if namespace exists
if ! kubectl get namespace microservices &> /dev/null; then
    echo "FAIL: Namespace 'microservices' not found"
    exit 1
fi

# Check if PVC exists
if ! kubectl get pvc data-pvc -n microservices &> /dev/null; then
    echo "FAIL: PVC 'data-pvc' not found in namespace microservices"
    exit 1
fi

# Check if PVC is bound
PVC_STATUS=$(kubectl get pvc data-pvc -n microservices -o jsonpath='{.status.phase}')
if [ "$PVC_STATUS" != "Bound" ]; then
    echo "FAIL: PVC 'data-pvc' is not bound, status: $PVC_STATUS"
    exit 1
fi

# Check if deployment exists
if ! kubectl get deployment storage-app -n microservices &> /dev/null; then
    echo "FAIL: Deployment 'storage-app' not found in namespace microservices"
    exit 1
fi

# Check if deployment is ready
READY_REPLICAS=$(kubectl get deployment storage-app -n microservices -o jsonpath='{.status.readyReplicas}')
if [ "$READY_REPLICAS" != "1" ]; then
    echo "FAIL: Deployment 'storage-app' should have 1 ready replica, found: $READY_REPLICAS"
    exit 1
fi

# Check if pod is using the PVC
POD_NAME=$(kubectl get pods -n microservices -l app=storage-app -o jsonpath='{.items[0].metadata.name}')
if [ -z "$POD_NAME" ]; then
    echo "FAIL: No pod found with label app=storage-app"
    exit 1
fi

# Verify the volume mount exists in the pod
VOLUME_MOUNTS=$(kubectl get pod "$POD_NAME" -n microservices -o jsonpath='{.spec.containers[0].volumeMounts[*].mountPath}')
if [[ "$VOLUME_MOUNTS" != *"/data"* ]]; then
    echo "FAIL: Volume not mounted at /data in pod"
    exit 1
fi

echo "PASS: Persistent Volume Claims validation successful"
