#!/bin/bash
set -e

# Setup for Question 3: Pod Security Standards
echo "Setting up environment for Pod Security Standards scenario..."

# Create namespace with Pod Security Standards
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: secure-pods
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
EOF

# Create ServiceAccount
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: secure-sa
  namespace: secure-pods
EOF

echo "Pod Security Standards environment setup complete!"
echo "Namespace: secure-pods"
echo "ServiceAccount: secure-sa"
echo "Pod Security Standard: restricted"
