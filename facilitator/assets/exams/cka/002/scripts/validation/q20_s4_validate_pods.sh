#!/bin/bash
set -e

# Check if deployment exists
kubectl get deployment failing-app -n troubleshoot || {
    echo "Deployment failing-app not found in namespace troubleshoot"
    exit 1
}

# Check if all pods are running
READY_PODS=$(kubectl get deployment failing-app -n troubleshoot -o jsonpath='{.status.readyReplicas}')
if [[ "$READY_PODS" != "3" ]]; then
    echo "Not all pods are ready. Expected 3, got $READY_PODS"
    exit 1
fi

# Check pod status
PODS=$(kubectl get pods -n troubleshoot -l app=failing-app -o jsonpath='{.items[*].metadata.name}')
for POD in $PODS; do
    # Check pod phase
    PHASE=$(kubectl get pod $POD -n troubleshoot -o jsonpath='{.status.phase}')
    if [[ "$PHASE" != "Running" ]]; then
        echo "Pod $POD is not running. Current phase: $PHASE"
        exit 1
    fi
    
    # Check container ready status
    READY=$(kubectl get pod $POD -n troubleshoot -o jsonpath='{.status.containerStatuses[0].ready}')
    if [[ "$READY" != "true" ]]; then
        echo "Container in pod $POD is not ready"
        exit 1
    fi
    
    # Check for recent restarts
    RESTARTS=$(kubectl get pod $POD -n troubleshoot -o jsonpath='{.status.containerStatuses[0].restartCount}')
    if [[ "$RESTARTS" -gt 0 ]]; then
        # Check if the last restart was recent (within last minute)
        LAST_RESTART=$(kubectl get pod $POD -n troubleshoot -o jsonpath='{.status.containerStatuses[0].lastState.terminated.finishedAt}')
        if [[ -n "$LAST_RESTART" ]]; then
            RESTART_TIME=$(date -d "$LAST_RESTART" +%s)
            NOW=$(date +%s)
            DIFF=$((NOW - RESTART_TIME))
            if [[ "$DIFF" -lt 60 ]]; then
                echo "Pod $POD has recent restarts"
                exit 1
            fi
        fi
    fi
done

# Test pod functionality
for POD in $PODS; do
    # Test nginx is serving on port 80
    kubectl exec $POD -n troubleshoot -- curl -s localhost:80 > /dev/null || {
        echo "Pod $POD is not serving content on port 80"
        exit 1
    }
done

echo "Pod validation successful"
exit 0 