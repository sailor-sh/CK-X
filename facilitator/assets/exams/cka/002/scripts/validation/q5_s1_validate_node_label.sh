#!/bin/bash
set -e

# Check if node exists
kubectl get node k3d-cluster-agent-1 || {
    echo "Node k3d-cluster-agent-1 not found"
    exit 1
}

# Check if node has the required label
LABEL_VALUE=$(kubectl get node k3d-cluster-agent-1 -o jsonpath='{.metadata.labels.disk}')
if [[ "$LABEL_VALUE" != "ssd" ]]; then
    echo "Node k3d-cluster-agent-1 does not have the correct label. Expected disk=ssd, got disk=$LABEL_VALUE"
    exit 1
fi

echo "Node label validation successful"
exit 0 