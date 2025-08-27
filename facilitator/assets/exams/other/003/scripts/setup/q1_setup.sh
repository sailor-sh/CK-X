#!/bin/bash

# Question 1 Setup: Microservices Architecture Foundation
# Create namespaces and basic infrastructure for microservices platform

set -e

echo "Setting up Microservices Architecture Foundation..."

# Create dedicated namespaces
kubectl create namespace microservices --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace ingress-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace cicd --dry-run=client -o yaml | kubectl apply -f -

# Label namespaces for organization
kubectl label namespace microservices tier=application --overwrite
kubectl label namespace monitoring tier=infrastructure --overwrite
kubectl label namespace ingress-system tier=networking --overwrite
kubectl label namespace cicd tier=pipeline --overwrite

# Create service accounts for microservices
kubectl create serviceaccount microservice-sa -n microservices --dry-run=client -o yaml | kubectl apply -f -

# Create basic network policies for microservices
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: microservices-baseline
  namespace: microservices
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          tier: networking
    - namespaceSelector:
        matchLabels:
          tier: monitoring
    - podSelector: {}
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          tier: monitoring
  - to:
    - podSelector: {}
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 443
EOF

# Create configmap for microservices configuration
kubectl create configmap microservice-config \
  --from-literal=environment=development \
  --from-literal=log_level=info \
  --from-literal=service_discovery_enabled=true \
  --from-literal=metrics_endpoint=/metrics \
  -n microservices --dry-run=client -o yaml | kubectl apply -f -

# Create secret for inter-service communication
kubectl create secret generic service-credentials \
  --from-literal=api_key=microservice-api-key-12345 \
  --from-literal=jwt_secret=jwt-secret-for-services \
  -n microservices --dry-run=client -o yaml | kubectl apply -f -

# Create PVC for shared data
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-data-pvc
  namespace: microservices
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
EOF

echo "Microservices foundation setup completed successfully!"
