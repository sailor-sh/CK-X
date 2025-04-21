#!/bin/bash
set -e

# Check if deployment exists
kubectl get deployment nginx -n kustomize || {
    echo "Deployment nginx not found in namespace kustomize"
    exit 1
}

# Check replicas
REPLICAS=$(kubectl get deployment nginx -n kustomize -o jsonpath='{.spec.replicas}')
if [[ "$REPLICAS" != "3" ]]; then
    echo "Incorrect number of replicas. Expected 3, got $REPLICAS"
    exit 1
fi

# Check environment label
ENV_LABEL=$(kubectl get deployment nginx -n kustomize -o jsonpath='{.metadata.labels.environment}')
if [[ "$ENV_LABEL" != "production" ]]; then
    echo "Incorrect environment label. Expected production, got $ENV_LABEL"
    exit 1
fi

# Check if pods are running
READY_PODS=$(kubectl get deployment nginx -n kustomize -o jsonpath='{.status.readyReplicas}')
if [[ "$READY_PODS" != "3" ]]; then
    echo "Not all pods are ready. Expected 3, got $READY_PODS"
    exit 1
fi

# Check if pods have the environment label
POD_LABEL=$(kubectl get pods -n kustomize -l app=nginx -o jsonpath='{.items[0].metadata.labels.environment}')
if [[ "$POD_LABEL" != "production" ]]; then
    echo "Pods do not have correct environment label"
    exit 1
fi

echo "Resources validation successful"
exit 0 