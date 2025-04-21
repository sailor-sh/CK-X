#!/bin/bash
set -e

# Check if volume mount exists
MOUNT_PATH=$(kubectl get pod data-pod -n storage-task -o jsonpath='{.spec.containers[0].volumeMounts[?(@.name=="data")].mountPath}')
if [[ "$MOUNT_PATH" != "/usr/share/nginx/html" ]]; then
    echo "Volume not mounted at correct path. Expected '/usr/share/nginx/html', got '$MOUNT_PATH'"
    exit 1
fi

# Check if volume is using the PVC
VOLUME_PVC=$(kubectl get pod data-pod -n storage-task -o jsonpath='{.spec.volumes[?(@.name=="data")].persistentVolumeClaim.claimName}')
if [[ "$VOLUME_PVC" != "data-pvc" ]]; then
    echo "Pod is not using the correct PVC. Expected 'data-pvc', got '$VOLUME_PVC'"
    exit 1
fi

echo "Volume mount validation successful"
exit 0 