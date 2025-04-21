#!/bin/bash
set -e

NAMESPACE="security"

# Check if namespace exists
kubectl get namespace "$NAMESPACE" > /dev/null || {
    echo "Namespace '$NAMESPACE' not found"
    exit 1
}

# Check enforce label
ENFORCE=$(kubectl get namespace "$NAMESPACE" -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}')
if [[ "$ENFORCE" != "restricted" ]]; then
    echo "Namespace '$NAMESPACE' does not have enforce=restricted label"
    exit 1
fi

# Check enforce-version label
VERSION=$(kubectl get namespace "$NAMESPACE" -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce-version}')
if [[ "$VERSION" != "latest" ]]; then
    echo "Namespace '$NAMESPACE' does not have enforce-version=latest label"
    exit 1
fi

echo "PSA label validation successful"
exit 0
