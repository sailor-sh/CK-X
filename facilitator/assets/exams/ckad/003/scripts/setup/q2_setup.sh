#!/bin/bash
set -e

# Setup for Question 2: ConfigMaps and Secrets Management
echo "Setting up environment for ConfigMaps and Secrets scenario..."

# Create namespace
kubectl create namespace config-demo --dry-run=client -o yaml | kubectl apply -f -

# Create some initial ConfigMaps and Secrets
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: basic-config
  namespace: config-demo
data:
  environment: "development"
  debug: "true"
  max_connections: "100"
---
apiVersion: v1
kind: Secret
metadata:
  name: basic-secret
  namespace: config-demo
type: Opaque
data:
  username: YWRtaW4=  # admin
  password: cGFzc3dvcmQ=  # password
EOF

echo "Environment setup completed for Question 2 - ConfigMaps and Secrets"
