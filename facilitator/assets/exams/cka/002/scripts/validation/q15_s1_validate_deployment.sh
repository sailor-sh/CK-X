#!/bin/bash
set -e

# Check if deployment exists
kubectl get deployment resource-consumer -n monitoring || {
    echo "Deployment resource-consumer not found in namespace monitoring"
    exit 1
}

# Check replicas
REPLICAS=$(kubectl get deployment resource-consumer -n monitoring -o jsonpath='{.spec.replicas}')
if [[ "$REPLICAS" != "3" ]]; then
    echo "Incorrect number of replicas. Expected 3, got $REPLICAS"
    exit 1
fi

# Check image
IMAGE=$(kubectl get deployment resource-consumer -n monitoring -o jsonpath='{.spec.template.spec.containers[0].image}')
if [[ "$IMAGE" != "gcr.io/kubernetes-e2e-test-images/resource-consumer:1.5" ]]; then
    echo "Incorrect image. Expected gcr.io/kubernetes-e2e-test-images/resource-consumer:1.5, got $IMAGE"
    exit 1
fi

# Check resource requests
CPU_REQUEST=$(kubectl get deployment resource-consumer -n monitoring -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}')
if [[ "$CPU_REQUEST" != "100m" ]]; then
    echo "Incorrect CPU request. Expected 100m, got $CPU_REQUEST"
    exit 1
fi

MEM_REQUEST=$(kubectl get deployment resource-consumer -n monitoring -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}')
if [[ "$MEM_REQUEST" != "128Mi" ]]; then
    echo "Incorrect memory request. Expected 128Mi, got $MEM_REQUEST"
    exit 1
fi

# Check resource limits
CPU_LIMIT=$(kubectl get deployment resource-consumer -n monitoring -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}')
if [[ "$CPU_LIMIT" != "200m" ]]; then
    echo "Incorrect CPU limit. Expected 200m, got $CPU_LIMIT"
    exit 1
fi

MEM_LIMIT=$(kubectl get deployment resource-consumer -n monitoring -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}')
if [[ "$MEM_LIMIT" != "256Mi" ]]; then
    echo "Incorrect memory limit. Expected 256Mi, got $MEM_LIMIT"
    exit 1
fi

echo "Deployment validation successful"
exit 0 