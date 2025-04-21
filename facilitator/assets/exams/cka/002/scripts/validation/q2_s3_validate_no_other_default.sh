#!/bin/bash
set -e

# Count number of default StorageClasses
DEFAULT_COUNT=$(kubectl get storageclass -o jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}' | wc -w)

if [[ "$DEFAULT_COUNT" -ne 1 ]]; then
    echo "Found $DEFAULT_COUNT default StorageClasses. Expected exactly 1"
    exit 1
fi

# Verify the only default is our StorageClass
DEFAULT_SC=$(kubectl get storageclass -o jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}')
if [[ "$DEFAULT_SC" != "fast-local" ]]; then
    echo "Wrong StorageClass is default. Expected 'fast-local', got '$DEFAULT_SC'"
    exit 1
fi

echo "No other default StorageClass validation successful"
exit 0 