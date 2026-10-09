#!/bin/bash
set -e

# Setup for Question 3: StatefulSet with Persistent Storage
echo "Setting up environment for StatefulSet scenario..."

# Create namespace
kubectl create namespace data-services --dry-run=client -o yaml | kubectl apply -f -

# Ensure storage class exists
kubectl get storageclass standard || kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
EOF

# Create a service for the StatefulSet (will be used by students)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: redis-cluster-service
  namespace: data-services
spec:
  clusterIP: None  # Headless service for StatefulSet
  selector:
    app: redis-cluster
  ports:
  - port: 6379
    targetPort: 6379
    name: redis
EOF

echo "Environment setup completed for Question 3 - StatefulSet with storage"
