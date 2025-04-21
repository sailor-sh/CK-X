#!/bin/bash
set -e

# Create namespace (reusing scheduling namespace)
kubectl create namespace scheduling --dry-run=client -o yaml | kubectl apply -f -

# Delete any existing PriorityClasses
kubectl delete priorityclass high-priority low-priority 2>/dev/null || true

# # Create the PriorityClasses
# kubectl create -f - <<EOF
# apiVersion: scheduling.k8s.io/v1
# kind: PriorityClass
# metadata:
#   name: high-priority
# value: 1000
# globalDefault: false
# description: "High priority class for testing"
# ---
# apiVersion: scheduling.k8s.io/v1
# kind: PriorityClass
# metadata:
#   name: low-priority
# value: 100
# globalDefault: false
# description: "Low priority class for testing"
# EOF

echo "Setup completed for Question 19" 