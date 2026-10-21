#!/usr/bin/env bash
set -euo pipefail
# Validates the service's targetPort matches the deployment's containerPort
# Get deployment container port
DEPLOYMENT_PORT=$(kubectl -n svc-fix-endpoints get deploy manager-api-deployment -o jsonpath='{.spec.template.spec.containers[0].ports[0].containerPort}')
# Get service target port
SERVICE_TARGET_PORT=$(kubectl -n svc-fix-endpoints get svc manager-api-svc -o jsonpath='{.spec.ports[0].targetPort}')

if [ "$DEPLOYMENT_PORT" != "$SERVICE_TARGET_PORT" ]; then
    echo "Service targetPort ($SERVICE_TARGET_PORT) does not match deployment containerPort ($DEPLOYMENT_PORT)"
    exit 1
fi