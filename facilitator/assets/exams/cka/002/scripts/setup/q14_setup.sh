#!/bin/bash
set -e

# Create namespace
kubectl create namespace limits --dry-run=client -o yaml | kubectl apply -f -

# Remove any existing LimitRange or ResourceQuota
kubectl delete limitrange --all -n limits 2>/dev/null || true
kubectl delete resourcequota --all -n limits 2>/dev/null || true

echo "Setup completed for Question 14" 