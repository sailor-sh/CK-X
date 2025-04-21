#!/bin/bash
set -e

# Create namespace
kubectl create namespace storage-task --dry-run=client -o yaml | kubectl apply -f -

# Ensure the standard storage class exists
kubectl get storageclass standard || kubectl create -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
EOF

echo "Setup completed for Question 1" 