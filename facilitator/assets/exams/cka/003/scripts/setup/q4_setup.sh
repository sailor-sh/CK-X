#!/bin/bash
set -e

# Setup for Question 4: DaemonSet for Logging
echo "Setting up environment for DaemonSet logging scenario..."

# Create namespace
kubectl create namespace logging --dry-run=client -o yaml | kubectl apply -f -

# Create some sample applications that generate logs
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-1
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-app-1
  template:
    metadata:
      labels:
        app: web-app-1
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        volumeMounts:
        - name: log-volume
          mountPath: /var/log/nginx
      volumes:
      - name: log-volume
        hostPath:
          path: /var/log/containers
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-2
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-app-2
  template:
    metadata:
      labels:
        app: web-app-2
    spec:
      containers:
      - name: httpd
        image: httpd:alpine
        volumeMounts:
        - name: log-volume
          mountPath: /var/log/httpd
      volumes:
      - name: log-volume
        hostPath:
          path: /var/log/containers
EOF

echo "Waiting for applications to be ready..."
kubectl rollout status deployment/web-app-1 --timeout=60s
kubectl rollout status deployment/web-app-2 --timeout=60s

# Create log directories on nodes (simulated)
mkdir -p /tmp/node-logs

echo "Environment setup completed for Question 4 - DaemonSet logging"
