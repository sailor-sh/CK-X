#!/bin/bash

# Setup for Question 22: api-gateway in namespace platform

set -euo pipefail

NAMESPACE="platform"
DEPLOYMENT="api-gateway"
SERVICE="api-gateway-svc"

if kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
  kubectl delete namespace "$NAMESPACE" --ignore-not-found=true --wait=true
fi
kubectl delete deployment "$DEPLOYMENT" -n "$NAMESPACE" --ignore-not-found=true || true
kubectl delete service "$SERVICE" -n "$NAMESPACE" --ignore-not-found=true || true

echo "Setup complete for Question 22."
exit 0

