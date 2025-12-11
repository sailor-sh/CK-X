#!/bin/bash
set -e

NAMESPACE="q011"

kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Create deployment without liveness probes
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: no-liveness
  namespace: $NAMESPACE
spec:
  replicas: 2
  selector:
    matchLabels:
      app: test
  template:
    metadata:
      labels:
        app: test
    spec:
      containers:
      - name: app
        image: nginx:latest
        ports:
        - containerPort: 80
EOF

echo "✓ Q011 setup complete: Deployment without liveness probes created in namespace $NAMESPACE"
