#!/bin/bash
set -e

# Check if StatefulSet exists
kubectl get statefulset web -n stateful || {
    echo "StatefulSet web not found in namespace stateful"
    exit 1
}

# Check replicas
REPLICAS=$(kubectl get statefulset web -n stateful -o jsonpath='{.spec.replicas}')
if [[ "$REPLICAS" != "3" ]]; then
    echo "Incorrect number of replicas. Expected 3, got $REPLICAS"
    exit 1
fi

# Check image
IMAGE=$(kubectl get statefulset web -n stateful -o jsonpath='{.spec.template.spec.containers[0].image}')
if [[ "$IMAGE" != *"nginx"* ]]; then
    echo "StatefulSet is not using nginx image. Current image: $IMAGE"
    exit 1
fi

# Check volume mount
MOUNT_PATH=$(kubectl get statefulset web -n stateful -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}')
if [[ "$MOUNT_PATH" != "/usr/share/nginx/html" ]]; then
    echo "Incorrect volume mount path. Expected /usr/share/nginx/html, got $MOUNT_PATH"
    exit 1
fi

# Check volume claim template
STORAGE_CLASS=$(kubectl get statefulset web -n stateful -o jsonpath='{.spec.volumeClaimTemplates[0].spec.storageClassName}')
if [[ "$STORAGE_CLASS" != "cold" ]]; then
    echo "Incorrect storage class. Expected cold, got $STORAGE_CLASS"
    exit 1
fi

STORAGE_SIZE=$(kubectl get statefulset web -n stateful -o jsonpath='{.spec.volumeClaimTemplates[0].spec.resources.requests.storage}')
if [[ "$STORAGE_SIZE" != "1Gi" ]]; then
    echo "Incorrect storage size. Expected 1Gi, got $STORAGE_SIZE"
    exit 1
fi

# Check if pods are running
READY_PODS=$(kubectl get statefulset web -n stateful -o jsonpath='{.status.readyReplicas}')
if [[ "$READY_PODS" != "3" ]]; then
    echo "Not all pods are ready. Expected 3, got $READY_PODS"
    exit 1
fi

echo "StatefulSet validation successful"
exit 0 