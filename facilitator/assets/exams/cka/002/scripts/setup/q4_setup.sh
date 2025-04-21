#!/bin/bash
set -e

# Create namespace
kubectl create namespace scaling --dry-run=client -o yaml | kubectl apply -f -

# Enable metrics-server if not present
kubectl get deployment metrics-server -n kube-system || {
  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
  # Wait for metrics-server to be ready
  kubectl wait --for=condition=available --timeout=180s deployment/metrics-server -n kube-system
}

echo "Setup completed for Question 4" 