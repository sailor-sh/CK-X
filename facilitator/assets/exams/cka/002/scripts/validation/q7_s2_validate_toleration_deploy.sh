#!/bin/bash
set -e

# Check if deployment exists
kubectl get deployment toleration-deploy -n scheduling || {
    echo "Deployment toleration-deploy not found in namespace scheduling"
    exit 1
}

# Check replicas
REPLICAS=$(kubectl get deployment toleration-deploy -n scheduling -o jsonpath='{.spec.replicas}')
if [[ "$REPLICAS" != "2" ]]; then
    echo "Incorrect number of replicas. Expected 2, got $REPLICAS"
    exit 1
fi

# Check if using nginx image
IMAGE=$(kubectl get deployment toleration-deploy -n scheduling -o jsonpath='{.spec.template.spec.containers[0].image}')
if [[ "$IMAGE" != *"nginx"* ]]; then
    echo "Deployment is not using nginx image. Current image: $IMAGE"
    exit 1
fi

# Check toleration configuration
TOLERATION_KEY=$(kubectl get deployment toleration-deploy -n scheduling -o jsonpath='{.spec.template.spec.tolerations[?(@.key=="special-workload")].key}')
if [[ "$TOLERATION_KEY" != "special-workload" ]]; then
    echo "Toleration key not found or incorrect"
    exit 1
fi

TOLERATION_VALUE=$(kubectl get deployment toleration-deploy -n scheduling -o jsonpath='{.spec.template.spec.tolerations[?(@.key=="special-workload")].value}')
if [[ "$TOLERATION_VALUE" != "true" ]]; then
    echo "Incorrect toleration value. Expected 'true', got '$TOLERATION_VALUE'"
    exit 1
fi

TOLERATION_EFFECT=$(kubectl get deployment toleration-deploy -n scheduling -o jsonpath='{.spec.template.spec.tolerations[?(@.key=="special-workload")].effect}')
if [[ "$TOLERATION_EFFECT" != "NoSchedule" ]]; then
    echo "Incorrect toleration effect. Expected 'NoSchedule', got '$TOLERATION_EFFECT'"
    exit 1
fi

# Check if pods are running
READY_PODS=$(kubectl get deployment toleration-deploy -n scheduling -o jsonpath='{.status.readyReplicas}')
if [[ "$READY_PODS" != "2" ]]; then
    echo "Not all pods are ready. Expected 2, got $READY_PODS"
    exit 1
fi

echo "Toleration deployment validation successful"
exit 0 