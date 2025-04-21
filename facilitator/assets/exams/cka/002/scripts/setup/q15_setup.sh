#!/bin/bash
set -e

# Create namespace
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Pre-pull the resource consumer image to speed up deployment
kubectl run pull-resource-consumer --image=gcr.io/kubernetes-e2e-test-images/resource-consumer:1.5 -n monitoring --dry-run=client -o yaml | kubectl apply -f -

# Wait for the pull pod to complete
sleep 10

# Clean up the pull pod
kubectl delete pod pull-resource-consumer -n monitoring 2>/dev/null || true

echo "Setup completed for Question 15" 