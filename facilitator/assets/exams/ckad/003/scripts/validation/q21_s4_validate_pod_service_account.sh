#!/usr/bin/env bash
set -euo pipefail
# Validates that the pods are using the 'sa-sun-deploy' service account
SERVICE_ACCOUNT=$(kubectl -n p2-deploy-svc get deploy sunny -o jsonpath='{.spec.template.spec.serviceAccountName}')

if [ "$SERVICE_ACCOUNT" != "sa-sun-deploy" ]; then
    echo "Pods are using service account $SERVICE_ACCOUNT, expected sa-sun-deploy"
    exit 1
fi