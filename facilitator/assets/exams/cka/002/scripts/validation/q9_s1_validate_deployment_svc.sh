#!/bin/bash
set -e

# Check if deployment exists
kubectl get deployment web-app -n dns-debug || {
    echo "Deployment web-app not found in namespace dns-debug"
    exit 1
}

# Check replicas
REPLICAS=$(kubectl get deployment web-app -n dns-debug -o jsonpath='{.spec.replicas}')
if [[ "$REPLICAS" != "3" ]]; then
    echo "Incorrect number of replicas. Expected 3, got $REPLICAS"
    exit 1
fi

# Check image
IMAGE=$(kubectl get deployment web-app -n dns-debug -o jsonpath='{.spec.template.spec.containers[0].image}')
if [[ "$IMAGE" != *"nginx"* ]]; then
    echo "Deployment is not using nginx image. Current image: $IMAGE"
    exit 1
fi

# Check if service exists
kubectl get service web-svc -n dns-debug || {
    echo "Service web-svc not found in namespace dns-debug"
    exit 1
}

# Check service type
SERVICE_TYPE=$(kubectl get service web-svc -n dns-debug -o jsonpath='{.spec.type}')
if [[ "$SERVICE_TYPE" != "ClusterIP" ]]; then
    echo "Incorrect service type. Expected ClusterIP, got $SERVICE_TYPE"
    exit 1
fi

# Check service selector
SELECTOR=$(kubectl get service web-svc -n dns-debug -o jsonpath='{.spec.selector.app}')
if [[ "$SELECTOR" != "web-app" ]]; then
    echo "Incorrect service selector. Expected app=web-app, got app=$SELECTOR"
    exit 1
fi

# Check if pods are running
READY_PODS=$(kubectl get deployment web-app -n dns-debug -o jsonpath='{.status.readyReplicas}')
if [[ "$READY_PODS" != "3" ]]; then
    echo "Not all pods are ready. Expected 3, got $READY_PODS"
    exit 1
fi

echo "Deployment and service validation successful"
exit 0 