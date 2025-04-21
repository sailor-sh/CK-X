#!/bin/bash
set -e

NAMESPACE="upgrade"
DEPLOYMENT="app-v1"
HISTORY_FILE="/tmp/exam/rollout-history.txt"

# Check if deployment exists
kubectl get deployment $DEPLOYMENT -n $NAMESPACE > /dev/null || {
    echo "Deployment $DEPLOYMENT not found in namespace $NAMESPACE"
    exit 1
}

# Check current image
CURRENT_IMAGE=$(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}')
if [[ "$CURRENT_IMAGE" != "nginx:1.19" ]]; then
    echo "Deployment is not using the expected image nginx:1.19. Got $CURRENT_IMAGE"
    exit 1
fi

# Check both images exist in RS history
RS_IMAGES=$(kubectl get rs -n $NAMESPACE -l app=app-v1 -o jsonpath='{range .items[*]}{.spec.template.spec.containers[0].image}{"\n"}{end}')

echo "$RS_IMAGES" | grep -q "nginx:1.19" || {
    echo "ReplicaSet with image nginx:1.19 not found"
    exit 1
}

echo "$RS_IMAGES" | grep -q "nginx:1.20" || {
    echo "ReplicaSet with image nginx:1.20 not found"
    exit 1
}

# Check rollout history file exists
if [[ ! -f "$HISTORY_FILE" ]]; then
    echo "Rollout history file not found at $HISTORY_FILE"
    exit 1
fi

# Check all pods are ready
READY_PODS=$(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.status.readyReplicas}')
if [[ "$READY_PODS" != "4" ]]; then
    echo "Expected 4 ready pods, but got $READY_PODS"
    exit 1
fi

# Ensure no pods are running nginx:1.20
PODS_WITH_20=$(kubectl get pods -n $NAMESPACE -l app=app-v1 -o jsonpath='{range .items[*]}{.metadata.name} {.spec.containers[0].image}{"\n"}{end}' | grep "nginx:1.20" || true)
if [[ -n "$PODS_WITH_20" ]]; then
    echo "Some pods are still running nginx:1.20:"
    echo "$PODS_WITH_20"
    exit 1
fi

echo "✅ Validation successful: rollback confirmed, both images used, and all pods healthy"
exit 0
