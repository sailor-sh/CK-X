#!/bin/bash
set -e

# Check if pod exists
kubectl get pod secure-pod -n security || {
    echo "Pod secure-pod not found in namespace security"
    exit 1
}

# Check if pod is running
POD_STATUS=$(kubectl get pod secure-pod -n security -o jsonpath='{.status.phase}')
if [[ "$POD_STATUS" != "Running" ]]; then
    echo "Pod is not in Running state. Current state: $POD_STATUS"
    exit 1
fi

# Check if pod is using nginx image
POD_IMAGE=$(kubectl get pod secure-pod -n security -o jsonpath='{.spec.containers[0].image}')
if [[ "$POD_IMAGE" != *"nginx"* ]]; then
    echo "Pod is not using nginx image. Current image: $POD_IMAGE"
    exit 1
fi

# Check if pod is running as non-root
RUN_AS_USER=$(kubectl get pod secure-pod -n security -o jsonpath='{.spec.securityContext.runAsNonRoot}')
if [[ "$RUN_AS_USER" != "true" ]]; then
    echo "Pod is not configured to run as non-root user"
    exit 1
fi

# Check if pod has no privileged containers
PRIVILEGED=$(kubectl get pod secure-pod -n security -o jsonpath='{.spec.containers[0].securityContext.privileged}')
if [[ "$PRIVILEGED" == "true" ]]; then
    echo "Pod has privileged container"
    exit 1
fi

echo "Pod validation successful"
exit 0 