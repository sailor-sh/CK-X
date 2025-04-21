#!/bin/bash
set -e

# Check if all pods are running
READY_PODS=$(kubectl get deployment app-scheduling -n scheduling -o jsonpath='{.status.readyReplicas}')
if [[ "$READY_PODS" != "3" ]]; then
    echo "Not all pods are ready. Expected 3, got $READY_PODS"
    exit 1
fi

# Get all pods
PODS=$(kubectl get pods -n scheduling -l app=app-scheduling -o jsonpath='{.items[*].metadata.name}')

# Check each pod's node placement
for POD in $PODS; do
    NODE=$(kubectl get pod $POD -n scheduling -o jsonpath='{.spec.nodeName}')
    if [[ "$NODE" != "k3d-cluster-agent-1" ]]; then
        echo "Pod $POD is running on wrong node. Expected k3d-cluster-agent-1, got $NODE"
        exit 1
    fi
done

echo "Pod placement validation successful"
exit 0 