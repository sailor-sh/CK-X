#!/bin/bash
set -e

# Check if deployment exists
kubectl get deployment failing-app -n troubleshoot || {
    echo "Deployment failing-app not found in namespace troubleshoot"
    exit 1
}

# Check memory limit configuration
MEM_LIMIT=$(kubectl get deployment failing-app -n troubleshoot -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}')
if [[ "$MEM_LIMIT" != "256Mi" ]]; then
    echo "Incorrect memory limit. Expected 256Mi, got $MEM_LIMIT"
    exit 1
fi

# Check if memory limit is correctly applied to pods
PODS=$(kubectl get pods -n troubleshoot -l app=failing-app -o jsonpath='{.items[*].metadata.name}')
for POD in $PODS; do
    POD_MEM_LIMIT=$(kubectl get pod $POD -n troubleshoot -o jsonpath='{.spec.containers[0].resources.limits.memory}')
    if [[ "$POD_MEM_LIMIT" != "256Mi" ]]; then
        echo "Pod $POD has incorrect memory limit. Expected 256Mi, got $POD_MEM_LIMIT"
        exit 1
    fi
done

# Check if pods are not being OOMKilled
for POD in $PODS; do
    RESTARTS=$(kubectl get pod $POD -n troubleshoot -o jsonpath='{.status.containerStatuses[0].restartCount}')
    LAST_STATE=$(kubectl get pod $POD -n troubleshoot -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}')
    
    if [[ "$LAST_STATE" == "OOMKilled" ]]; then
        echo "Pod $POD was terminated due to OOMKilled"
        exit 1
    fi
done

echo "Memory limit validation successful"
exit 0 