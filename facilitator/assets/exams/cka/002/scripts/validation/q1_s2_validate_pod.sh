#!/bin/bash
set -e

# Check if pod exists
kubectl get pod data-pod -n storage-task || {
    echo "Pod data-pod not found in namespace storage-task"
    exit 1
}

# Check if pod is running
POD_STATUS=$(kubectl get pod data-pod -n storage-task -o jsonpath='{.status.phase}')
if [[ "$POD_STATUS" != "Running" ]]; then
    echo "Pod is not in Running state. Current state: $POD_STATUS"
    exit 1
fi

# Check if pod is using nginx image
POD_IMAGE=$(kubectl get pod data-pod -n storage-task -o jsonpath='{.spec.containers[0].image}')
if [[ "$POD_IMAGE" != *"nginx"* ]]; then
    echo "Pod is not using nginx image. Current image: $POD_IMAGE"
    exit 1
fi

echo "Pod validation successful"
exit 0 