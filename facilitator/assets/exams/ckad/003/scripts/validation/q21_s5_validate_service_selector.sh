#!/usr/bin/env bash
set -euo pipefail
# Ensures the service selector correctly targets the deployment pods
# Get deployment labels
DEPLOYMENT_LABELS=$(kubectl -n p2-deploy-svc get deploy sunny -o jsonpath='{.spec.template.metadata.labels}')
# Get service selector
SERVICE_SELECTOR=$(kubectl -n p2-deploy-svc get svc sun-srv -o jsonpath='{.spec.selector}')

# Check if they match
if [ "$DEPLOYMENT_LABELS" != "$SERVICE_SELECTOR" ]; then
    echo "Service selector does not match deployment labels"
    echo "Deployment labels: $DEPLOYMENT_LABELS"
    echo "Service selector: $SERVICE_SELECTOR"
    exit 1
fi