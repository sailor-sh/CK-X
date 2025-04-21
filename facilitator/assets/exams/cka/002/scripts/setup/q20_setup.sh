#!/bin/bash
set -e

# Create namespace
kubectl create namespace troubleshoot --dry-run=client -o yaml | kubectl apply -f -

# Create the failing deployment
kubectl create -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: failing-app
  namespace: troubleshoot
spec:
  replicas: 3
  selector:
    matchLabels:
      app: failing-app
  template:
    metadata:
      labels:
        app: failing-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 8080
        resources:
          limits:
            memory: "64Mi"
            cpu: "100m"
        livenessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 3
          periodSeconds: 3
EOF

echo "Setup completed for Question 20" 