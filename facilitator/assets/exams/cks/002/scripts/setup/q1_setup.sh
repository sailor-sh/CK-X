#!/bin/bash
set -e

# Setup for Question 1: RBAC Implementation
echo "Setting up environment for RBAC scenario..."

# Create namespaces
kubectl create namespace dev-team --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace prod-team --dry-run=client -o yaml | kubectl apply -f -

# Create some sample resources in each namespace
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dev-app
  namespace: dev-team
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dev-app
  template:
    metadata:
      labels:
        app: dev-app
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prod-app
  namespace: prod-team
spec:
  replicas: 2
  selector:
    matchLabels:
      app: prod-app
  template:
    metadata:
      labels:
        app: prod-app
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
---
apiVersion: v1
kind: Secret
metadata:
  name: sensitive-data
  namespace: prod-team
type: Opaque
data:
  api-key: c3VwZXItc2VjcmV0LWtleQ==  # super-secret-key
EOF

echo "Environment setup completed for Question 1 - RBAC"
