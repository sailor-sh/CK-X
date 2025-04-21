#!/bin/bash
set -e

# Check if deployment exists
kubectl get deployment web-release-nginx -n helm-test || {
    echo "Deployment web-release-nginx not found in namespace helm-test"
    exit 1
}

# Check if all pods are running
READY_PODS=$(kubectl get deployment web-release-nginx -n helm-test -o jsonpath='{.status.readyReplicas}')
if [[ "$READY_PODS" != "2" ]]; then
    echo "Not all pods are ready. Expected 2, got $READY_PODS"
    exit 1
fi

# Check if pods are using correct image
POD_IMAGE=$(kubectl get deployment web-release-nginx -n helm-test -o jsonpath='{.spec.template.spec.containers[0].image}')
if [[ ! "$POD_IMAGE" =~ "nginx" ]]; then
    echo "Pods are not using nginx image. Current image: $POD_IMAGE"
    exit 1
fi

# Check if service is accessible
SERVICE_PORT=$(kubectl get service web-release-nginx -n helm-test -o jsonpath='{.spec.ports[0].nodePort}')
if [[ -z "$SERVICE_PORT" ]]; then
    echo "NodePort not configured for service"
    exit 1
fi

echo "Deployment validation successful"
exit 0 