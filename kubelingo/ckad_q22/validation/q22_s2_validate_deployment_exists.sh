#!/bin/bash

# Validate Deployment 'api-gateway' exists in namespace 'platform'
NAMESPACE="platform"
DEPLOYMENT="api-gateway"

if kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "Success: Deployment '$DEPLOYMENT' exists in namespace '$NAMESPACE'"
  exit 0
else
  echo "Error: Deployment '$DEPLOYMENT' not found in namespace '$NAMESPACE'"
  exit 1
fi

