#!/bin/bash
set -e

# Check if pods are running
READY_PODS=$(kubectl get deployment resource-consumer -n monitoring -o jsonpath='{.status.readyReplicas}')
if [[ "$READY_PODS" != "3" ]]; then
    echo "Not all pods are ready. Expected 3, got $READY_PODS"
    exit 1
fi

# Get all pods
PODS=$(kubectl get pods -n monitoring -l app=resource-consumer -o jsonpath='{.items[*].metadata.name}')

# Check each pod's configuration
for POD in $PODS; do
    # Check if pod is running
    POD_STATUS=$(kubectl get pod $POD -n monitoring -o jsonpath='{.status.phase}')
    if [[ "$POD_STATUS" != "Running" ]]; then
        echo "Pod $POD is not running. Current status: $POD_STATUS"
        exit 1
    fi
    
    # Check resource requests
    CPU_REQUEST=$(kubectl get pod $POD -n monitoring -o jsonpath='{.spec.containers[0].resources.requests.cpu}')
    if [[ "$CPU_REQUEST" != "100m" ]]; then
        echo "Pod $POD has incorrect CPU request. Expected 100m, got $CPU_REQUEST"
        exit 1
    fi
    
    MEM_REQUEST=$(kubectl get pod $POD -n monitoring -o jsonpath='{.spec.containers[0].resources.requests.memory}')
    if [[ "$MEM_REQUEST" != "128Mi" ]]; then
        echo "Pod $POD has incorrect memory request. Expected 128Mi, got $MEM_REQUEST"
        exit 1
    fi
    
    # Check if metrics are being collected
    kubectl top pod $POD -n monitoring > /dev/null || {
        echo "Unable to get metrics for pod $POD"
        exit 1
    }
done

echo "Pods validation successful"
exit 0 