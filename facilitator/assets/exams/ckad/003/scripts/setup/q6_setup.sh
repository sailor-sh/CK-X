#!/bin/bash
set -e

# Setup for Question 6: Horizontal Pod Autoscaler
echo "Setting up environment for HPA scenario..."

# Create namespace
kubectl create namespace scaling-demo --dry-run=client -o yaml | kubectl apply -f -

# Deploy a basic application for scaling
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cpu-intensive-app
  namespace: scaling-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cpu-intensive-app
  template:
    metadata:
      labels:
        app: cpu-intensive-app
    spec:
      containers:
      - name: php-apache
        image: registry.k8s.io/hpa-example
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 200m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
---
apiVersion: v1
kind: Service
metadata:
  name: cpu-intensive-service
  namespace: scaling-demo
spec:
  selector:
    app: cpu-intensive-app
  ports:
  - port: 80
    targetPort: 80
EOF

echo "Waiting for deployment to be ready..."
kubectl rollout status deployment/cpu-intensive-app -n scaling-demo --timeout=60s

echo "Environment setup completed for Question 6 - HPA"
