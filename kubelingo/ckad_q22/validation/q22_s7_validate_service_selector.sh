#!/bin/bash

# Validate Service selector matches app=api and tier=edge
NAMESPACE="platform"
SERVICE="api-gateway-svc"

if ! kubectl get service "$SERVICE" -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "Error: Service '$SERVICE' not found in namespace '$NAMESPACE'"
  exit 1
fi

APP=$(kubectl get service "$SERVICE" -n "$NAMESPACE" -o jsonpath='{.spec.selector.app}' 2>/dev/null)
TIER=$(kubectl get service "$SERVICE" -n "$NAMESPACE" -o jsonpath='{.spec.selector.tier}' 2>/dev/null)

if [ "$APP" != "api" ]; then
  echo "Error: Expected selector app=api, got app='$APP'"
  exit 1
fi

if [ "$TIER" != "edge" ]; then
  echo "Error: Expected selector tier=edge, got tier='$TIER'"
  exit 1
fi

echo "Success: Service selector matches app=api and tier=edge"
exit 0

