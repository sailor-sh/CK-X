#!/bin/bash
set -e

# Create namespace
kubectl create namespace storage-class --dry-run=client -o yaml | kubectl apply -f -

# Create a dummy default storage class to test removal of default
kubectl create -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: default-test
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: rancher.io/local-path
EOF

echo "Setup completed for Question 2" 