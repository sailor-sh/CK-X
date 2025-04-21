#!/bin/bash
set -e

# Check if StorageClass exists
kubectl get storageclass fast-local || {
    echo "StorageClass fast-local not found"
    exit 1
}

# Validate provisioner
PROVISIONER=$(kubectl get storageclass fast-local -o jsonpath='{.provisioner}')
if [[ "$PROVISIONER" != "rancher.io/local-path" ]]; then
    echo "Incorrect provisioner. Expected 'rancher.io/local-path', got '$PROVISIONER'"
    exit 1
fi

# Validate volumeBindingMode
BINDING_MODE=$(kubectl get storageclass fast-local -o jsonpath='{.volumeBindingMode}')
if [[ "$BINDING_MODE" != "WaitForFirstConsumer" ]]; then
    echo "Incorrect volumeBindingMode. Expected 'WaitForFirstConsumer', got '$BINDING_MODE'"
    exit 1
fi

echo "StorageClass validation successful"
exit 0 