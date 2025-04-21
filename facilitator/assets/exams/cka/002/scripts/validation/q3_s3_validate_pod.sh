#!/bin/bash
set -e

# Check if pod exists
kubectl get pod manual-pod -n manual-storage || {
    echo "Pod manual-pod not found in namespace manual-storage"
    exit 1
}

# Check if pod is running
POD_STATUS=$(kubectl get pod manual-pod -n manual-storage -o jsonpath='{.status.phase}')
if [[ "$POD_STATUS" != "Running" ]]; then
    echo "Pod is not in Running state. Current state: $POD_STATUS"
    exit 1
fi

# Check if pod is using busybox image
POD_IMAGE=$(kubectl get pod manual-pod -n manual-storage -o jsonpath='{.spec.containers[0].image}')
if [[ "$POD_IMAGE" != *"busybox"* ]]; then
    echo "Pod is not using busybox image. Current image: $POD_IMAGE"
    exit 1
fi

# Check if volume is mounted correctly
MOUNT_PATH=$(kubectl get pod manual-pod -n manual-storage -o jsonpath='{.spec.containers[0].volumeMounts[0].mountPath}')
if [[ "$MOUNT_PATH" != "/data" ]]; then
    echo "Volume not mounted at correct path. Expected '/data', got '$MOUNT_PATH'"
    exit 1
fi

# Check if the correct PVC is used
VOLUME_PVC=$(kubectl get pod manual-pod -n manual-storage -o jsonpath='{.spec.volumes[0].persistentVolumeClaim.claimName}')
if [[ "$VOLUME_PVC" != "manual-pvc" ]]; then
    echo "Pod is not using the correct PVC. Expected 'manual-pvc', got '$VOLUME_PVC'"
    exit 1
fi

# Check if command is set correctly
POD_COMMAND=$(kubectl get pod manual-pod -n manual-storage -o jsonpath='{.spec.containers[0].command[0]}')
if [[ "$POD_COMMAND" != "sleep" ]]; then
    echo "Pod command is not set to sleep"
    exit 1
fi

POD_ARGS=$(kubectl get pod manual-pod -n manual-storage -o jsonpath='{.spec.containers[0].command[1]}')
if [[ "$POD_ARGS" != "3600" ]]; then
    echo "Pod sleep duration is not set to 3600"
    exit 1
fi

echo "Pod validation successful"
exit 0 