#!/bin/bash
set -e

# Create namespace
kubectl create namespace scheduling --dry-run=client -o yaml | kubectl apply -f -

# Ensure the target node exists and is labeled with hostname
kubectl label node k3d-cluster-agent-1 kubernetes.io/hostname=k3d-cluster-agent-1 --overwrite

echo "Setup completed for Question 5" 