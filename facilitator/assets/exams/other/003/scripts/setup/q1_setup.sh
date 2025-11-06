#!/bin/bash

# Setup for Question 1: Troubleshoot and fix a broken deployment

# Create the troubleshooting namespace if it doesn't exist already
if ! kubectl get namespace troubleshooting &> /dev/null; then
    kubectl create namespace troubleshooting
fi

# Delete any existing deployment with the same name
kubectl delete deployment broken-app -n troubleshooting --ignore-not-found=true

# Create a broken deployment with an invalid image name
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: broken-app
  namespace: troubleshooting
spec:
  replicas: 2
  selector:
    matchLabels:
      app: broken-app
  template:
    metadata:
      labels:
        app: broken-app
    spec:
      containers:
      - name: app
        image: nginx:nonexistentversion  # This image tag doesn't exist
        ports:
        - containerPort: 80
EOF

echo "Setup complete for Question 1: Created broken deployment 'broken-app' in namespace 'troubleshooting'"
exit 0