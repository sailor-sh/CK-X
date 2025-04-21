#!/bin/bash
set -e

# Check if deployment exists
kubectl get deployment scaling-app -n scaling || {
    echo "Deployment scaling-app not found in namespace scaling"
    exit 1
}

# Check replicas
REPLICAS=$(kubectl get deployment scaling-app -n scaling -o jsonpath='{.spec.replicas}')
if [[ "$REPLICAS" != "2" ]]; then
    echo "Incorrect number of replicas. Expected 2, got $REPLICAS"
    exit 1
fi

# Check image
IMAGE=$(kubectl get deployment scaling-app -n scaling -o jsonpath='{.spec.template.spec.containers[0].image}')
if [[ "$IMAGE" != *"nginx"* ]]; then
    echo "Incorrect image. Expected nginx, got $IMAGE"
    exit 1
fi

# Check resource requests
CPU_REQUEST=$(kubectl get deployment scaling-app -n scaling -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}')
if [[ "$CPU_REQUEST" != "200m" ]]; then
    echo "Incorrect CPU request. Expected 200m, got $CPU_REQUEST"
    exit 1
fi

MEM_REQUEST=$(kubectl get deployment scaling-app -n scaling -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}')
if [[ "$MEM_REQUEST" != "256Mi" ]]; then
    echo "Incorrect memory request. Expected 256Mi, got $MEM_REQUEST"
    exit 1
fi

# Check resource limits
CPU_LIMIT=$(kubectl get deployment scaling-app -n scaling -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}')
if [[ "$CPU_LIMIT" != "500m" ]]; then
    echo "Incorrect CPU limit. Expected 500m, got $CPU_LIMIT"
    exit 1
fi

MEM_LIMIT=$(kubectl get deployment scaling-app -n scaling -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}')
if [[ "$MEM_LIMIT" != "512Mi" ]]; then
    echo "Incorrect memory limit. Expected 512Mi, got $MEM_LIMIT"
    exit 1
fi

echo "Deployment validation successful"
exit 0 