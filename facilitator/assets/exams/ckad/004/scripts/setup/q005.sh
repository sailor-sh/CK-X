#!/bin/bash
set -e

NAMESPACE="q005"

kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Create pod with init container
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: init-pod
  namespace: $NAMESPACE
spec:
  initContainers:
  - name: init
    image: busybox:latest
    command: ['sh', '-c', 'echo "Initialization complete" > /shared/init.txt']
    volumeMounts:
    - name: shared-volume
      mountPath: /shared
  containers:
  - name: app
    image: nginx:latest
    volumeMounts:
    - name: shared-volume
      mountPath: /shared
    ports:
    - containerPort: 80
  volumes:
  - name: shared-volume
    emptyDir: {}
EOF

echo "✓ Q005 setup complete: Pod with init container created in namespace $NAMESPACE"
