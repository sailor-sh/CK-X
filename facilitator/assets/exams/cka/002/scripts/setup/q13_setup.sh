#!/bin/bash
set -e

# Create namespace
kubectl create namespace gateway --dry-run=client -o yaml | kubectl apply -f -

# Install Gateway API CRDs
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v0.8.0/standard-install.yaml

# Wait for CRDs to be ready
kubectl wait --for=condition=established --timeout=60s crd/gateways.gateway.networking.k8s.io
kubectl wait --for=condition=established --timeout=60s crd/httproutes.gateway.networking.k8s.io

echo "Setup completed for Question 13" 