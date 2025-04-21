#!/bin/bash
set -e

# Create namespace
kubectl create namespace upgrade --dry-run=client -o yaml | kubectl apply -f -

# Create directory for rollout history
mkdir -p /tmp/exam

# Clean up the pull pods
kubectl delete pod pull-nginx-1-19 pull-nginx-1-20 -n upgrade

echo "Setup completed for Question 18" 