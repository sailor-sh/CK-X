#!/bin/bash
set -e

# Check if PV exists
kubectl get pv manual-pv || {
    echo "PV manual-pv not found"
    exit 1
}

# Validate storage size
STORAGE_SIZE=$(kubectl get pv manual-pv -o jsonpath='{.spec.capacity.storage}')
if [[ "$STORAGE_SIZE" != "1Gi" ]]; then
    echo "Incorrect storage size. Expected '1Gi', got '$STORAGE_SIZE'"
    exit 1
fi

# Validate access mode
ACCESS_MODE=$(kubectl get pv manual-pv -o jsonpath='{.spec.accessModes[0]}')
if [[ "$ACCESS_MODE" != "ReadWriteOnce" ]]; then
    echo "Incorrect access mode. Expected 'ReadWriteOnce', got '$ACCESS_MODE'"
    exit 1
fi

# Validate host path
HOST_PATH=$(kubectl get pv manual-pv -o jsonpath='{.spec.hostPath.path}')
if [[ "$HOST_PATH" != "/mnt/data" ]]; then
    echo "Incorrect host path. Expected '/mnt/data', got '$HOST_PATH'"
    exit 1
fi

# Validate node affinity
NODE_HOSTNAME=$(kubectl get pv manual-pv -o jsonpath='{.spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[?(@.key=="kubernetes.io/hostname")].values[0]}')
if [[ "$NODE_HOSTNAME" != "k3d-cluster-agent-0" ]]; then
    echo "Incorrect node affinity. Expected 'k3d-cluster-agent-0', got '$NODE_HOSTNAME'"
    exit 1
fi

echo "PV validation successful"
exit 0 