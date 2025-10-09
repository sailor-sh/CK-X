#!/bin/bash

# Validate container name 'gateway' and image 'nginx:1.25-alpine'
NAMESPACE="platform"
DEPLOYMENT="api-gateway"

if ! kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "Error: Deployment '$DEPLOYMENT' not found in namespace '$NAMESPACE'"
  exit 1
fi

NAME=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].name}' 2>/dev/null)
IMAGE=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)

if [ "$NAME" != "gateway" ]; then
  echo "Error: Expected container name 'gateway', got '$NAME'"
  exit 1
fi

if [ "$IMAGE" != "nginx:1.25-alpine" ]; then
  echo "Error: Expected image 'nginx:1.25-alpine', got '$IMAGE'"
  exit 1
fi

echo "Success: Container name and image match ('gateway', 'nginx:1.25-alpine')"
exit 0

