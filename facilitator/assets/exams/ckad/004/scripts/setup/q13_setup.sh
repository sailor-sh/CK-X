#!/bin/bash
set -e

NAMESPACE="q013"

kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Create pod without proper environment variables
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: env-pod
  namespace: $NAMESPACE
spec:
  containers:
  - name: app
    image: nginx:latest
    ports:
    - containerPort: 80
EOF

echo "✓ Q013 setup complete: Pod without environment variables created in namespace $NAMESPACE"
