#!/bin/bash
set -e

NAMESPACE="q008"

kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Create resources with various labels for selector testing
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: prod-pod-1
  namespace: $NAMESPACE
  labels:
    env: production
    app: web
spec:
  containers:
  - name: app
    image: nginx:latest
---
apiVersion: v1
kind: Pod
metadata:
  name: dev-pod-1
  namespace: $NAMESPACE
  labels:
    env: development
    app: api
spec:
  containers:
  - name: app
    image: nginx:latest
---
apiVersion: v1
kind: Pod
metadata:
  name: prod-pod-2
  namespace: $NAMESPACE
  labels:
    env: production
    app: api
spec:
  containers:
  - name: app
    image: nginx:latest
EOF

echo "✓ Q008 setup complete: Resources with labels created in namespace $NAMESPACE"
