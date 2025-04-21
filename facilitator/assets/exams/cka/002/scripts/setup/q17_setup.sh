#!/bin/bash
set -e

# Create namespace
kubectl create namespace network --dry-run=client -o yaml | kubectl apply -f -

# Ensure NetworkPolicy API is enabled
kubectl get networkpolicies -n network || {
  echo "NetworkPolicy API is not enabled"
  exit 1
}

# Delete any existing network policies
kubectl delete networkpolicy --all -n network 2>/dev/null || true

echo "Setup completed for Question 17" 