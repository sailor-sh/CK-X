#!/bin/bash
set -e

# Create namespace
kubectl create namespace helm-test --dry-run=client -o yaml | kubectl apply -f -

# Ensure helm is installed
helm version || {
  echo "Helm is not installed"
  exit 1
}

# Remove bitnami repo if it exists (to test adding it)
helm repo remove bitnami 2>/dev/null || true

echo "Setup completed for Question 11" 