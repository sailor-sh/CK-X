#!/bin/bash

# Setup for Question 22: api-gateway in namespace platform

set -euo pipefail

NAMESPACE="platform"
DEPLOYMENT="api-gateway"
SERVICE="api-gateway-svc"

# Ensure a clean state by deleting the namespace (and all contained resources) if it exists
if kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
  kubectl delete namespace "$NAMESPACE" --ignore-not-found=true --wait=true
fi

# Best-effort deletion in case namespace was not present but named resources exist elsewhere
kubectl delete deployment "$DEPLOYMENT" -n "$NAMESPACE" --ignore-not-found=true || true
kubectl delete service "$SERVICE" -n "$NAMESPACE" --ignore-not-found=true || true

echo "Setup complete for Question 22: Clean environment for creating Deployment '$DEPLOYMENT' and Service '$SERVICE' in namespace '$NAMESPACE'"
exit 0

