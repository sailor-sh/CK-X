#!/bin/bash
set -e

NAMESPACE="q009"

kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Create ResourceQuota
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: $NAMESPACE
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi
EOF

# Create pods without resource limits for testing
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: no-limits-pod
  namespace: $NAMESPACE
spec:
  containers:
  - name: app
    image: nginx:latest
    ports:
    - containerPort: 80
EOF

echo "✓ Q009 setup complete: ResourceQuota and pod without limits created in namespace $NAMESPACE"
