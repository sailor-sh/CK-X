#!/bin/bash
set -e

# Setup for Question 4: Security Contexts and Permissions
echo "Setting up environment for Security Contexts scenario..."

# Create namespace
kubectl create namespace secure-apps --dry-run=client -o yaml | kubectl apply -f -

# Create a ServiceAccount
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-service-account
  namespace: secure-apps
---
apiVersion: v1
kind: Secret
metadata:
  name: app-tls-secret
  namespace: secure-apps
type: kubernetes.io/tls
data:
  tls.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0t  # dummy cert
  tls.key: LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0t  # dummy key
EOF

echo "Environment setup completed for Question 4 - Security Contexts"
