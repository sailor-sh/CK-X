#!/bin/bash
set -e

# Setup for Question 5: Node Troubleshooting
echo "Setting up environment for Node troubleshooting scenario..."

# Create a problematic pod that should fail to schedule
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: problematic-pod
  namespace: default
spec:
  containers:
  - name: app
    image: nginx:alpine
    resources:
      requests:
        memory: "999Gi"  # Intentionally impossible requirement
        cpu: "100"
  nodeSelector:
    nonexistent-label: "true"  # Intentionally bad node selector
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-deployment
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-app
  template:
    metadata:
      labels:
        app: test-app
    spec:
      containers:
      - name: app
        image: nginx:alpine
EOF

# Create a namespace for node-related resources
kubectl create namespace node-management --dry-run=client -o yaml | kubectl apply -f -

echo "Environment setup completed for Question 5 - Node troubleshooting"
