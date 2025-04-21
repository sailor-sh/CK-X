#!/bin/bash
set -e

# Check if deployment exists
kubectl get deployment normal-deploy -n scheduling || {
    echo "Deployment normal-deploy not found in namespace scheduling"
    exit 1
}

# Check replicas
REPLICAS=$(kubectl get deployment normal-deploy -n scheduling -o jsonpath='{.spec.replicas}')
if [[ "$REPLICAS" != "2" ]]; then
    echo "Incorrect number of replicas. Expected 2, got $REPLICAS"
    exit 1
fi

# Check if using nginx image
IMAGE=$(kubectl get deployment normal-deploy -n scheduling -o jsonpath='{.spec.template.spec.containers[0].image}')
if [[ "$IMAGE" != *"nginx"* ]]; then
    echo "Deployment is not using nginx image. Current image: $IMAGE"
    exit 1
fi

# Check that there are no tolerations for special-workload
TOLERATIONS=$(kubectl get deployment normal-deploy -n scheduling -o jsonpath='{.spec.template.spec.tolerations[?(@.key=="special-workload")]}')
if [[ -n "$TOLERATIONS" ]]; then
    echo "Deployment should not have tolerations for special-workload"
    exit 1
fi

# Check if pods are running
READY_PODS=$(kubectl get deployment normal-deploy -n scheduling -o jsonpath='{.status.readyReplicas}')
if [[ "$READY_PODS" != "2" ]]; then
    echo "Not all pods are ready. Expected 2, got $READY_PODS"
    exit 1
fi

# Verify pods are not on tainted node
PODS=$(kubectl get pods -n scheduling -l app=normal-deploy -o jsonpath='{.items[*].metadata.name}')
for POD in $PODS; do
    NODE=$(kubectl get pod $POD -n scheduling -o jsonpath='{.spec.nodeName}')
    if [[ "$NODE" == "k3d-cluster-agent-1" ]]; then
        echo "Pod $POD is scheduled on tainted node k3d-cluster-agent-1"
        exit 1
    fi
done

echo "Normal deployment validation successful"
exit 0 