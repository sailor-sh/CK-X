#!/bin/bash
set -e

NAMESPACE="secrets-volume"

kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Create pod that generates logs
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: logging-pod
  namespace: $NAMESPACE
spec:
  containers:
  - name: app
    image: busybox:latest
    command: ['sh', '-c', 'while true; do echo "$(date): Application running"; sleep 5; done']
EOF

echo "✓ Q12 setup complete: Pod with logging capability created in namespace $NAMESPACE"
