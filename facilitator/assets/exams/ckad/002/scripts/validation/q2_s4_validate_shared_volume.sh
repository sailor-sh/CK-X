#!/bin/bash

# Validate that the shared volume is configured correctly
# Check if volume exists
VOLUME_NAME=$(kubectl get pod multi-container-pod -n multi-container -o jsonpath='{.spec.volumes[?(@.name=="log-volume")].name}' 2>/dev/null)

if [[ "$VOLUME_NAME" == "log-volume" ]]; then
    # Volume exists, now check if it's mounted in both containers
    MAIN_CONTAINER_MOUNT=$(kubectl get pod multi-container-pod -n multi-container -o jsonpath='{.spec.containers[?(@.name=="main-container")].volumeMounts[?(@.name=="log-volume")]}' 2>/dev/null)
    SIDECAR_CONTAINER_MOUNT=$(kubectl get pod multi-container-pod -n multi-container -o jsonpath='{.spec.containers[?(@.name=="sidecar-container")].volumeMounts[?(@.name=="log-volume")].mountPath}' 2>/dev/null)

    if [[ "$MAIN_CONTAINER_MOUNT" == *"/var/log"* && "$SIDECAR_CONTAINER_MOUNT" == "/var/log" ]]; then
        # Both containers have the volume mounted at the correct path
        exit 0
    else
        echo "Volume mounts are not configured correctly."
        echo "Main container mount path: $MAIN_CONTAINER_MOUNT (expected: /var/log)"
        echo "Sidecar container mount path: $SIDECAR_CONTAINER_MOUNT (expected: /var/log)"
        exit 1
    fi
else
    echo "Volume 'log-volume' does not exist in pod 'multi-container-pod'"
    exit 1
fi