#!/bin/bash

# Validate Service ports: port 8080 -> targetPort 80
NAMESPACE="platform"
SERVICE="api-gateway-svc"

if ! kubectl get service "$SERVICE" -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "Error: Service '$SERVICE' not found in namespace '$NAMESPACE'"
  exit 1
fi

PORT=$(kubectl get service "$SERVICE" -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)
TARGET=$(kubectl get service "$SERVICE" -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].targetPort}' 2>/dev/null)

if [ "$PORT" != "8080" ]; then
  echo "Error: Expected service port 8080, got '$PORT'"
  exit 1
fi

if [ "$TARGET" != "80" ]; then
  echo "Error: Expected service targetPort 80, got '$TARGET'"
  exit 1
fi

echo "Success: Service port 8080 forwards to targetPort 80"
exit 0

