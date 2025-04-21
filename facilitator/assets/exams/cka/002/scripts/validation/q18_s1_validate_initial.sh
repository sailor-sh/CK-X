#!/bin/bash
set -e

# Check if deployment exists
kubectl get deployment app-v1 -n upgrade || {
    echo "Deployment app-v1 not found in namespace upgrade"
    exit 1
}

# Check replicas
REPLICAS=$(kubectl get deployment app-v1 -n upgrade -o jsonpath='{.spec.replicas}')
if [[ "$REPLICAS" != "4" ]]; then
    echo "Incorrect number of replicas. Expected 4, got $REPLICAS"
    exit 1
fi

# Check image
IMAGE=$(kubectl get deployment app-v1 -n upgrade -o jsonpath='{.spec.template.spec.containers[0].image}')
if [[ "$IMAGE" != "nginx:1.19" ]]; then
    echo "Incorrect image. Expected nginx:1.19, got $IMAGE"
    exit 1
fi

# Check if pods are running
READY_PODS=$(kubectl get deployment app-v1 -n upgrade -o jsonpath='{.status.readyReplicas}')
if [[ "$READY_PODS" != "4" ]]; then
    echo "Not all pods are ready. Expected 4, got $READY_PODS"
    exit 1
fi

# Check deployment strategy
STRATEGY=$(kubectl get deployment app-v1 -n upgrade -o jsonpath='{.spec.strategy.type}')
if [[ "$STRATEGY" != "RollingUpdate" ]]; then
    echo "Incorrect deployment strategy. Expected RollingUpdate, got $STRATEGY"
    exit 1
fi

# Check max unavailable
MAX_UNAVAILABLE=$(kubectl get deployment app-v1 -n upgrade -o jsonpath='{.spec.strategy.rollingUpdate.maxUnavailable}')
if [[ "$MAX_UNAVAILABLE" != "1" ]]; then
    echo "Incorrect maxUnavailable. Expected 1, got $MAX_UNAVAILABLE"
    exit 1
fi

# Check max surge
MAX_SURGE=$(kubectl get deployment app-v1 -n upgrade -o jsonpath='{.spec.strategy.rollingUpdate.maxSurge}')
if [[ "$MAX_SURGE" != "1" ]]; then
    echo "Incorrect maxSurge. Expected 1, got $MAX_SURGE"
    exit 1
fi

echo "Initial deployment validation successful"
exit 0 