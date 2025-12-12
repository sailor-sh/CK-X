#!/bin/bash
set -e

NAMESPACE="q020"

kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Create deployment for autoscaling
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: scalable-app
  namespace: $NAMESPACE
spec:
  replicas: 2
  selector:
    matchLabels:
      app: scalable
  template:
    metadata:
      labels:
        app: scalable
    spec:
      containers:
      - name: app
        image: nginx:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
EOF

# Create HorizontalPodAutoscaler
cat <<EOF | kubectl apply -f -
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
  namespace: $NAMESPACE
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: scalable-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
EOF

echo "✓ Q020 setup complete: Deployment with HPA created in namespace $NAMESPACE"
