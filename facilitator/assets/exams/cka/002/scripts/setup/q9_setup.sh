#!/bin/bash
set -e

# Create namespace
kubectl create namespace dns-debug --dry-run=client -o yaml | kubectl apply -f -

# Ensure CoreDNS is running
kubectl rollout status deployment/coredns -n kube-system --timeout=30s || {
  echo "CoreDNS is not running properly"
  exit 1
}

echo "Setup completed for Question 9" 