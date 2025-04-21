#!/bin/bash
set -e

# Check if deployment exists
kubectl get deployment test-limits -n limits || {
    echo "Deployment test-limits not found in namespace limits"
    exit 1
}

# Check replicas
REPLICAS=$(kubectl get deployment test-limits -n limits -o jsonpath='{.spec.replicas}')
if [[ "$REPLICAS" != "2" ]]; then
    echo "Incorrect number of replicas. Expected 2, got $REPLICAS"
    exit 1
fi

# Check if pods are running
READY_PODS=$(kubectl get deployment test-limits -n limits -o jsonpath='{.status.readyReplicas}')
if [[ "$READY_PODS" != "2" ]]; then
    echo "Not all pods are ready. Expected 2, got $READY_PODS"
    exit 1
fi

# Check if pods respect LimitRange
PODS=$(kubectl get pods -n limits -l app=test-limits -o jsonpath='{.items[*].metadata.name}')
for POD in $PODS; do
    # Check resource requests
    CPU_REQUEST=$(kubectl get pod $POD -n limits -o jsonpath='{.spec.containers[0].resources.requests.cpu}')
    if [[ "$CPU_REQUEST" != "100m" ]]; then
        echo "Pod $POD has incorrect CPU request. Expected 100m, got $CPU_REQUEST"
        exit 1
    fi
    
    MEM_REQUEST=$(kubectl get pod $POD -n limits -o jsonpath='{.spec.containers[0].resources.requests.memory}')
    if [[ "$MEM_REQUEST" != "128Mi" ]]; then
        echo "Pod $POD has incorrect memory request. Expected 128Mi, got $MEM_REQUEST"
        exit 1
    fi
    
    # Check resource limits
    CPU_LIMIT=$(kubectl get pod $POD -n limits -o jsonpath='{.spec.containers[0].resources.limits.cpu}')
    if [[ "$CPU_LIMIT" != "200m" ]]; then
        echo "Pod $POD has incorrect CPU limit. Expected 200m, got $CPU_LIMIT"
        exit 1
    fi
    
    MEM_LIMIT=$(kubectl get pod $POD -n limits -o jsonpath='{.spec.containers[0].resources.limits.memory}')
    if [[ "$MEM_LIMIT" != "256Mi" ]]; then
        echo "Pod $POD has incorrect memory limit. Expected 256Mi, got $MEM_LIMIT"
        exit 1
    fi
done

echo "Deployment validation successful"
exit 0 