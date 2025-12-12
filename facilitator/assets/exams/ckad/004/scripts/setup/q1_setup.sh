#!/bin/bash
set -e

NAMESPACE="ckad-ns-a"

# Create namespace
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Create a basic pod for pod creation testing
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  namespace: $NAMESPACE
spec:
  containers:
  - name: app
    image: nginx:latest
    ports:
    - containerPort: 80
EOF

echo "✓ Q1 setup complete: Basic pod created in namespace $NAMESPACE"
