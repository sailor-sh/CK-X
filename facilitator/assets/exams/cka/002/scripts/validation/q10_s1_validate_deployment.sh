#!/bin/bash
set -e

# Check if deployment exists and has correct replicas
DEPLOY_STATUS=$(kubectl get deployment dns-app -n dns-config -o jsonpath='{.status.replicas},{.status.availableReplicas}' 2>/dev/null || echo "not found")
if [ "$DEPLOY_STATUS" = "not found" ]; then
    echo "Deployment dns-app not found"
    exit 1
fi

REPLICAS=$(echo $DEPLOY_STATUS | cut -d',' -f1)
AVAILABLE=$(echo $DEPLOY_STATUS | cut -d',' -f2)

if [ "$REPLICAS" != "2" ] || [ "$AVAILABLE" != "2" ]; then
    echo "Deployment does not have correct number of replicas"
    exit 1
fi

# Check if service exists and has correct port
SVC_PORT=$(kubectl get svc dns-svc -n dns-config -o jsonpath='{.spec.ports[0].port}' 2>/dev/null || echo "not found")
if [ "$SVC_PORT" = "not found" ]; then
    echo "Service dns-svc not found"
    exit 1
fi

if [ "$SVC_PORT" != "80" ]; then
    echo "Service port is not configured correctly"
    exit 1
fi

exit 0 