#!/bin/bash

# Validate Pod template labels include app=api and tier=edge
NAMESPACE="platform"
DEPLOYMENT="api-gateway"

if ! kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "Error: Deployment '$DEPLOYMENT' not found in namespace '$NAMESPACE'"
  exit 1
fi

APP=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.metadata.labels.app}' 2>/dev/null)
TIER=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.metadata.labels.tier}' 2>/dev/null)

if [ "$APP" != "api" ]; then
  echo "Error: Expected pod label app=api, got app='$APP'"
  exit 1
fi

if [ "$TIER" != "edge" ]; then
  echo "Error: Expected pod label tier=edge, got tier='$TIER'"
  exit 1
fi

echo "Success: Pod template labels include app=api and tier=edge"
exit 0

