#!/usr/bin/env bash
set -euo pipefail
# Validates that the service selector matches the deployment's labels
# Get deployment labels
DEPLOYMENT_LABELS=$(kubectl -n svc-fix-endpoints get deploy manager-api-deployment -o jsonpath='{.spec.template.metadata.labels}')
# Get service selector
SERVICE_SELECTOR=$(kubectl -n svc-fix-endpoints get svc manager-api-svc -o jsonpath='{.spec.selector}')

# Check if they match (both should have app: manager-api)
if [ "$DEPLOYMENT_LABELS" != "$SERVICE_SELECTOR" ]; then
    echo "Service selector does not match deployment labels"
    echo "Deployment labels: $DEPLOYMENT_LABELS"
    echo "Service selector: $SERVICE_SELECTOR"
    exit 1
fi