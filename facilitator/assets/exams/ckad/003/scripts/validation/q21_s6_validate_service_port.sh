#!/usr/bin/env bash
set -euo pipefail
# Validates the service is exposing port 9999
SERVICE_PORT=$(kubectl -n p2-deploy-svc get svc sun-srv -o jsonpath='{.spec.ports[0].port}')

if [ "$SERVICE_PORT" != "9999" ]; then
    echo "Service port is $SERVICE_PORT, expected 9999"
    exit 1
fi