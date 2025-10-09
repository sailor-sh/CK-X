#!/bin/bash

# Validate Service 'api-gateway-svc' exists and is ClusterIP
NAMESPACE="platform"
SERVICE="api-gateway-svc"

if ! kubectl get service "$SERVICE" -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "Error: Service '$SERVICE' not found in namespace '$NAMESPACE'"
  exit 1
fi

TYPE=$(kubectl get service "$SERVICE" -n "$NAMESPACE" -o jsonpath='{.spec.type}' 2>/dev/null)
if [ "$TYPE" != "ClusterIP" ]; then
  echo "Error: Expected Service type 'ClusterIP', got '$TYPE'"
  exit 1
fi

echo "Success: Service '$SERVICE' exists and is ClusterIP"
exit 0

