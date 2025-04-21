#!/bin/bash
set -e

# Check if release exists
helm status web-release -n helm-test || {
    echo "Helm release web-release not found in namespace helm-test"
    exit 1
}

# Check if it's using nginx chart
CHART=$(helm get manifest web-release -n helm-test | grep "chart:" | head -1)
if [[ ! "$CHART" =~ "nginx" ]]; then
    echo "Release is not using nginx chart"
    exit 1
fi

# Check if service type is NodePort
SERVICE_TYPE=$(kubectl get service web-release-nginx -n helm-test -o jsonpath='{.spec.type}')
if [[ "$SERVICE_TYPE" != "NodePort" ]]; then
    echo "Service type is not NodePort. Current type: $SERVICE_TYPE"
    exit 1
fi

# Check replica count
REPLICAS=$(kubectl get deployment web-release-nginx -n helm-test -o jsonpath='{.spec.replicas}')
if [[ "$REPLICAS" != "2" ]]; then
    echo "Incorrect number of replicas. Expected 2, got $REPLICAS"
    exit 1
fi

echo "Helm release validation successful"
exit 0 