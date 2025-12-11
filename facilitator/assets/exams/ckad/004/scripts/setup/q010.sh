#!/bin/bash
set -e

NAMESPACE="q010"

kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Create deployment without readiness probes
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: no-readiness
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

echo "✓ Q010 setup complete: Deployment without readiness probes created in namespace $NAMESPACE"
