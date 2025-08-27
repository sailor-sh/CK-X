#!/bin/bash
set -e

# Setup for Question 2: ETCD Backup and Cluster Maintenance
echo "Setting up environment for ETCD backup scenario..."

# Create sample resources that should be backed up
kubectl create namespace critical-apps --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: critical-apps
data:
  database_url: "postgresql://localhost:5432/myapp"
  redis_url: "redis://localhost:6379"
  log_level: "INFO"
---
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: critical-apps
type: Opaque
data:
  username: YWRtaW4=  # admin
  password: cGFzc3dvcmQ=  # password
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: critical-app
  namespace: critical-apps
spec:
  replicas: 2
  selector:
    matchLabels:
      app: critical-app
  template:
    metadata:
      labels:
        app: critical-app
    spec:
      containers:
      - name: app
        image: nginx:alpine
        env:
        - name: CONFIG_PATH
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: database_url
        - name: SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: username
EOF

echo "Waiting for critical application to be ready..."
kubectl rollout status deployment/critical-app -n critical-apps --timeout=60s

# Create ETCD backup directory if it doesn't exist
mkdir -p /tmp/etcd-backup

echo "Environment setup completed for Question 2 - ETCD backup"
