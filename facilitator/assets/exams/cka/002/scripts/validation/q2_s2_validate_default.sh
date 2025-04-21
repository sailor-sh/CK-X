#!/bin/bash
set -e

# Check if StorageClass is marked as default
IS_DEFAULT=$(kubectl get storageclass fast-local -o jsonpath='{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}')
if [[ "$IS_DEFAULT" != "true" ]]; then
    echo "StorageClass fast-local is not marked as default"
    exit 1
fi

echo "Default StorageClass validation successful"
exit 0 