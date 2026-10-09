#!/bin/bash
set -e

# Setup for Question 6: Resource Management and Health Probes
echo "Setting up environment for Resource Management scenario..."

# Create namespace
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -

# Deploy an application without proper resource limits and probes
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resource-hungry-app
  namespace: production
spec:
  replicas: 2
  selector:
    matchLabels:
      app: resource-hungry-app
  template:
    metadata:
      labels:
        app: resource-hungry-app
    spec:
      containers:
      - name: app
        image: nginx:alpine
        ports:
        - containerPort: 80
        # No resource limits or probes - students need to add them
---
apiVersion: v1
kind: Service
metadata:
  name: resource-hungry-service
  namespace: production
spec:
  selector:
    app: resource-hungry-app
  ports:
  - port: 80
    targetPort: 80
EOF

# Create a ResourceQuota for the namespace
kubectl apply -f - <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: production-quota
  namespace: production
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
    persistentvolumeclaims: "10"
    pods: "10"
EOF

echo "Waiting for deployment to be ready..."
kubectl rollout status deployment/resource-hungry-app -n production --timeout=60s

echo "Environment setup completed for Question 6 - Resource Management"
