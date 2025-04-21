#!/bin/bash
set -e

# Check if node exists
kubectl get node k3d-cluster-agent-1 || {
    echo "Node k3d-cluster-agent-1 not found"
    exit 1
}

# Check if taint exists
TAINT=$(kubectl get node k3d-cluster-agent-1 -o jsonpath='{.spec.taints[?(@.key=="special-workload")]}')
if [[ -z "$TAINT" ]]; then
    echo "Taint special-workload not found on node k3d-cluster-agent-1"
    exit 1
fi

# Check taint value
TAINT_VALUE=$(kubectl get node k3d-cluster-agent-1 -o jsonpath='{.spec.taints[?(@.key=="special-workload")].value}')
if [[ "$TAINT_VALUE" != "true" ]]; then
    echo "Incorrect taint value. Expected 'true', got '$TAINT_VALUE'"
    exit 1
fi

# Check taint effect
TAINT_EFFECT=$(kubectl get node k3d-cluster-agent-1 -o jsonpath='{.spec.taints[?(@.key=="special-workload")].effect}')
if [[ "$TAINT_EFFECT" != "NoSchedule" ]]; then
    echo "Incorrect taint effect. Expected 'NoSchedule', got '$TAINT_EFFECT'"
    exit 1
fi

echo "Node taint validation successful"
exit 0 