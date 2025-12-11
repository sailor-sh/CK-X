#!/bin/bash
set -e

NAMESPACE="q019"

kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Create DaemonSet
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: logging-daemon
  namespace: $NAMESPACE
spec:
  selector:
    matchLabels:
      app: logger
  template:
    metadata:
      labels:
        app: logger
    spec:
      containers:
      - name: logger
        image: busybox:latest
        command: ['sh', '-c', 'while true; do echo "Logging from $(hostname)"; sleep 30; done']
      hostNetwork: true
EOF

echo "✓ Q019 setup complete: DaemonSet created in namespace $NAMESPACE"
