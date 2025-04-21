#!/bin/bash
set -e

NAMESPACE="upgrade"
DEPLOYMENT="app-v1"

# Check if deployment exists
kubectl get deployment $DEPLOYMENT -n $NAMESPACE > /dev/null || {
    echo "Deployment $DEPLOYMENT not found in namespace $NAMESPACE"
    exit 1
}

# Check if current image is nginx:1.19
CURRENT_IMAGE=$(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}')
if [[ "$CURRENT_IMAGE" != "nginx:1.19" ]]; then
    echo "Deployment not rolled back. Expected image nginx:1.19, got $CURRENT_IMAGE"
    exit 1
fi

# Get list of ReplicaSets for this deployment
RS_LIST=$(kubectl get rs -n $NAMESPACE -l app=$DEPLOYMENT -o jsonpath='{range .items[*]}{.metadata.name} {.spec.template.spec.containers[0].image}{"\n"}{end}')

# Check if both versions exist
echo "$RS_LIST" | grep -q "nginx:1.19" || {
    echo "ReplicaSet with nginx:1.19 not found"
    exit 1
}

echo "$RS_LIST" | grep -q "nginx:1.20" || {
    echo "ReplicaSet with nginx:1.20 not found"
    exit 1
}

# Check all pods are ready
READY_PODS=$(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.status.readyReplicas}')
if [[ "$READY_PODS" != "4" ]]; then
    echo "Not all pods are ready. Expected 4, got $READY_PODS"
    exit 1
fi

# Check no pods are still using nginx:1.20
BAD_PODS=$(kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT -o jsonpath='{range .items[*]}{.metadata.name} {.spec.containers[0].image}{"\n"}{end}' | grep "nginx:1.20" || true)
if [[ -n "$BAD_PODS" ]]; then
    echo "Some pods are still using nginx:1.20:"
    echo "$BAD_PODS"
    exit 1
fi

echo "✅ Rollback validation successful"
exit 0
