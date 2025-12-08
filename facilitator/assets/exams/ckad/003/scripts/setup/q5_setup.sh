#!/bin/bash
set -e

# Setup for Question 5: Persistent Storage
echo "Setting up environment for Persistent Storage scenario..."

# Create namespace
kubectl create namespace storage-demo --dry-run=client -o yaml | kubectl apply -f -

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

# Create some sample data that should be persisted
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: init-data
  namespace: storage-demo
data:
  init.sql: |
    CREATE TABLE users (
      id SERIAL PRIMARY KEY,
      name VARCHAR(100),
      email VARCHAR(100)
    );
    INSERT INTO users (name, email) VALUES 
    ('John Doe', 'john@example.com'),
    ('Jane Smith', 'jane@example.com');
EOF

echo "Environment setup completed for Question 5 - Persistent Storage"
