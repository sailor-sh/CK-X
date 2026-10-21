#!/usr/bin/env bash
set -euo pipefail
# Ensures the deployment is in a ready state after the changes
READY_REPLICAS=$(kubectl -n sidecar-logging get deploy cleaner -o jsonpath='{.status.readyReplicas}')
DESIRED_REPLICAS=$(kubectl -n sidecar-logging get deploy cleaner -o jsonpath='{.status.replicas}')

if [ "$READY_REPLICAS" != "$DESIRED_REPLICAS" ]; then
    echo "Deployment not ready: $READY_REPLICAS/$DESIRED_REPLICAS replicas ready"
    exit 1
fi

# Also check that at least one pod is running
POD_STATUS=$(kubectl -n sidecar-logging get pod -l app=cleaner -o jsonpath='{.items[*].status.phase}')
if [ "$POD_STATUS" != "Running" ]; then
    echo "Pods are not in Running state: $POD_STATUS"
    exit 1
fi