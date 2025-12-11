#!/bin/bash
set -e

NAMESPACE="q022"

kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Create deployment for pod affinity testing
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-tier
  namespace: $NAMESPACE
spec:
  replicas: 2
  selector:
    matchLabels:
      tier: web
  template:
    metadata:
      labels:
        tier: web
    spec:
      containers:
      - name: web
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: cache-pod
  namespace: $NAMESPACE
  labels:
    tier: cache
spec:
  affinity:
    podAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: tier
              operator: In
              values:
              - web
          topologyKey: kubernetes.io/hostname
  containers:
  - name: cache
    image: redis:latest
    ports:
    - containerPort: 6379
EOF

echo "✓ Q022 setup complete: Web deployment and cache pod with pod affinity created in namespace $NAMESPACE"
