#!/bin/bash
set -e

NAMESPACE="q021"

kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Label nodes for affinity testing (label master/control-plane node)
kubectl label nodes --all disktype=ssd --overwrite || true

# Create pod requiring node affinity
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: affinity-pod
  namespace: $NAMESPACE
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd
  containers:
  - name: app
    image: nginx:latest
    ports:
    - containerPort: 80
EOF

echo "✓ Q021 setup complete: Pod with node affinity created in namespace $NAMESPACE"
