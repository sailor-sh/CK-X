#!/bin/bash
set -e

NAMESPACE="q02"

# Create the required directory structure for the question
mkdir -p /opt/course/1
chmod -R 777 /opt/course/1

kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Create deployment for rollout testing
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-deployment
  namespace: $NAMESPACE
spec:
  replicas: 3
  selector:
    matchLabels:
      app: test-app
  template:
    metadata:
      labels:
        app: test-app
    spec:
      containers:
      - name: app
        image: nginx:1.19
        ports:
        - containerPort: 80
EOF

echo "✓ Q2 setup complete: Deployment created in namespace $NAMESPACE and directory /opt/course/1 created"
