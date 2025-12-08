#!/bin/bash
set -e

# Setup for Question 2: Pod Security Standards
echo "Setting up environment for Pod Security Standards scenario..."

# Create namespace without security policies
kubectl create namespace security-test --dry-run=client -o yaml | kubectl apply -f -

# Deploy some insecure pods that should be blocked after implementing PSS
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: insecure-pod
  namespace: security-test
spec:
  containers:
  - name: container
    image: nginx:alpine
    securityContext:
      privileged: true
      runAsUser: 0
    volumeMounts:
    - name: host-volume
      mountPath: /host
  volumes:
  - name: host-volume
    hostPath:
      path: /
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-deployment
  namespace: security-test
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
      - name: container
        image: nginx:alpine
        securityContext:
          allowPrivilegeEscalation: true
EOF

echo "Environment setup completed for Question 2 - Pod Security Standards"
