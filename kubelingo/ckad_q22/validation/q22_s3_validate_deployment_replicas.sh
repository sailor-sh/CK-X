#!/bin/bash

# Validate Deployment replicas == 2
NAMESPACE="platform"
DEPLOYMENT="api-gateway"

if ! kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "Error: Deployment '$DEPLOYMENT' not found in namespace '$NAMESPACE'"
  exit 1
fi

REPLICAS=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ "$REPLICAS" = "2" ]; then
  echo "Success: Deployment '$DEPLOYMENT' has replicas=$REPLICAS"
  exit 0
else
  echo "Error: Expected replicas=2, got '$REPLICAS'"
  exit 1
fi

