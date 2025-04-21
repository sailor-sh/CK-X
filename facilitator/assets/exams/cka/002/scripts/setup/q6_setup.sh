#!/bin/bash
set -e

# Create namespace
kubectl create namespace security --dry-run=client -o yaml | kubectl apply -f -

# Enable PodSecurity admission controller if not already enabled
# Note: This might require cluster-level access and might not be possible in all environments

# Create the role and rolebinding for PSP
kubectl create -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: psp-role
  namespace: security
rules:
- apiGroups: ['policy']
  resources: ['podsecuritypolicies']
  verbs: ['use']
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: psp-role-binding
  namespace: security
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: psp-role
subjects:
- kind: ServiceAccount
  name: default
  namespace: security
EOF

echo "Setup completed for Question 6" 