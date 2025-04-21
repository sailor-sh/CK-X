#!/bin/bash
set -e

# Create namespace
kubectl create namespace stateful --dry-run=client -o yaml | kubectl apply -f -

# Ensure storage class exists
kubectl get storageclass cold || kubectl create -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: cold
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
EOF

echo "Setup completed for Question 8" 