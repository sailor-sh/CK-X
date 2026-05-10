#!/bin/bash
set -e

# Validation for Question 1: Multi-Container Pod Patterns
echo "Validating Multi-Container Pod scenario..."

# Check if namespace exists
if ! kubectl get namespace microservices &> /dev/null; then
    echo "FAIL: Namespace 'microservices' not found"
    exit 1
fi

# Check if ConfigMap exists
if ! kubectl get configmap sidecar-config -n microservices &> /dev/null; then
    echo "FAIL: ConfigMap 'sidecar-config' not found in namespace microservices"
    exit 1
fi

# Check if the main application pod exists and is running
if ! kubectl get pod app-with-sidecar -n microservices &> /dev/null; then
    echo "FAIL: Pod 'app-with-sidecar' not found in namespace microservices"
    exit 1
fi

# Check if pod has multiple containers
CONTAINER_COUNT=$(kubectl get pod app-with-sidecar -n microservices -o jsonpath='{.spec.containers[*].name}' | wc -w)
if [ "$CONTAINER_COUNT" -lt 2 ]; then
    echo "FAIL: Pod 'app-with-sidecar' should have at least 2 containers, found $CONTAINER_COUNT"
    exit 1
fi

# Check if pod is running
POD_STATUS=$(kubectl get pod app-with-sidecar -n microservices -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" != "Running" ]; then
    echo "FAIL: Pod 'app-with-sidecar' is not running, status: $POD_STATUS"
    exit 1
fi

echo "PASS: Multi-Container Pod validation successful"
