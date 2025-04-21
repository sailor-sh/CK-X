#!/bin/bash
set -e

# Check if pods are running
READY_PODS=$(kubectl get deployment scaling-app -n scaling -o jsonpath='{.status.readyReplicas}')
if [[ "$READY_PODS" != "2" ]]; then
    echo "Not all pods are ready. Expected 2, got $READY_PODS"
    exit 1
fi

# Get pod names
PODS=$(kubectl get pods -n scaling -l app=scaling-app -o jsonpath='{.items[*].metadata.name}')

# Check each pod's resource configuration
for POD in $PODS; do
    # Check CPU request
    CPU_REQUEST=$(kubectl get pod $POD -n scaling -o jsonpath='{.spec.containers[0].resources.requests.cpu}')
    if [[ "$CPU_REQUEST" != "200m" ]]; then
        echo "Pod $POD has incorrect CPU request. Expected 200m, got $CPU_REQUEST"
        exit 1
    fi

    # Check memory request
    MEM_REQUEST=$(kubectl get pod $POD -n scaling -o jsonpath='{.spec.containers[0].resources.requests.memory}')
    if [[ "$MEM_REQUEST" != "256Mi" ]]; then
        echo "Pod $POD has incorrect memory request. Expected 256Mi, got $MEM_REQUEST"
        exit 1
    fi

    # Check CPU limit
    CPU_LIMIT=$(kubectl get pod $POD -n scaling -o jsonpath='{.spec.containers[0].resources.limits.cpu}')
    if [[ "$CPU_LIMIT" != "500m" ]]; then
        echo "Pod $POD has incorrect CPU limit. Expected 500m, got $CPU_LIMIT"
        exit 1
    fi

    # Check memory limit
    MEM_LIMIT=$(kubectl get pod $POD -n scaling -o jsonpath='{.spec.containers[0].resources.limits.memory}')
    if [[ "$MEM_LIMIT" != "512Mi" ]]; then
        echo "Pod $POD has incorrect memory limit. Expected 512Mi, got $MEM_LIMIT"
        exit 1
    fi
done

echo "Resource configuration validation successful"
exit 0 