#!/bin/bash
set -e

NAMESPACE="q003"

kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Create backend deployment
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: $NAMESPACE
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: app
        image: nginx:latest
        ports:
        - containerPort: 80
EOF

# Create service for networking
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: $NAMESPACE
spec:
  selector:
    app: backend
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 80
EOF

echo "✓ Q003 setup complete: Service and backend deployment created in namespace $NAMESPACE"
