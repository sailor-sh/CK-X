#!/bin/bash
set -e

NAMESPACE="q006"

kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Create multi-container pod with sidecar
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: multi-container
  namespace: $NAMESPACE
spec:
  containers:
  - name: main-app
    image: nginx:latest
    ports:
    - containerPort: 80
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log/nginx
  - name: sidecar-logger
    image: busybox:latest
    command: ['sh', '-c', 'tail -f /var/log/nginx/access.log 2>/dev/null || sleep 3600']
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log/nginx
  volumes:
  - name: shared-logs
    emptyDir: {}
EOF

echo "✓ Q006 setup complete: Multi-container pod with sidecar created in namespace $NAMESPACE"
