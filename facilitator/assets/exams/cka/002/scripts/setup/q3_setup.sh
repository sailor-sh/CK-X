#!/bin/bash
set -e

# Create namespace
kubectl create namespace manual-storage --dry-run=client -o yaml | kubectl apply -f -

# Create the directory on the node (this assumes we have access to the node)
mkdir -p /mnt/data

# Label the node for identification
kubectl label node k3d-cluster-agent-0 kubernetes.io/hostname=k3d-cluster-agent-0 --overwrite

echo "Setup completed for Question 3" 