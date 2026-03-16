#!/usr/bin/env bash
set -euo pipefail
# Ensures the init container has the correct volume mount
# Check if init-con has the html volume mount
INIT_VOLUME_MOUNT=$(kubectl -n init-container get deploy test-init-container -o jsonpath='{.spec.template.spec.initContainers[?(@.name=="init-con")].volumeMounts[?(@.name=="html")].mountPath}')
if [ -z "$INIT_VOLUME_MOUNT" ]; then
    echo "Init container does not have html volume mount"
    echo "Debug: Checking if init container exists..."
    kubectl -n init-container get deploy test-init-container -o jsonpath='{.spec.template.spec.initContainers[*].name}'
    exit 1
fi

# Check if the mount path is correct
if [ "$INIT_VOLUME_MOUNT" != "/usr/share/nginx/html" ]; then
    echo "Init container volume mount path is $INIT_VOLUME_MOUNT, expected /usr/share/nginx/html"
    exit 1
fi