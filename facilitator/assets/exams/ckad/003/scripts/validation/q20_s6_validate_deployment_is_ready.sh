#!/usr/bin/env bash
set -euo pipefail
# Ensures the deployment is in a ready state after adding the probe
READY_REPLICAS=$(kubectl -n p1-liveness get deploy project-23-api -o jsonpath='{.status.readyReplicas}')
DESIRED_REPLICAS=$(kubectl -n p1-liveness get deploy project-23-api -o jsonpath='{.status.replicas}')

if [ "$READY_REPLICAS" != "$DESIRED_REPLICAS" ]; then
    echo "Deployment not ready: $READY_REPLICAS/$DESIRED_REPLICAS replicas ready"
    exit 1
fi