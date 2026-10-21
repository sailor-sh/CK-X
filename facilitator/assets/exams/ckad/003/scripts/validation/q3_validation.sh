#!/bin/bash
set -e

# Validation for Question 3: ConfigMaps and Secrets Management
echo "Validating ConfigMaps and Secrets Management scenario..."

# Check if namespace exists
if ! kubectl get namespace microservices &> /dev/null; then
    echo "FAIL: Namespace 'microservices' not found"
    exit 1
fi

# Check if ConfigMap exists
if ! kubectl get configmap app-config -n microservices &> /dev/null; then
    echo "FAIL: ConfigMap 'app-config' not found in namespace microservices"
    exit 1
fi

# Check if Secret exists
if ! kubectl get secret app-secrets -n microservices &> /dev/null; then
    echo "FAIL: Secret 'app-secrets' not found in namespace microservices"
    exit 1
fi

# Check if deployment exists
if ! kubectl get deployment config-app -n microservices &> /dev/null; then
    echo "FAIL: Deployment 'config-app' not found in namespace microservices"
    exit 1
fi

# Check if deployment is ready
READY_REPLICAS=$(kubectl get deployment config-app -n microservices -o jsonpath='{.status.readyReplicas}')
if [ "$READY_REPLICAS" != "1" ]; then
    echo "FAIL: Deployment 'config-app' should have 1 ready replica, found: $READY_REPLICAS"
    exit 1
fi

# Check if pod is using ConfigMap and Secret
POD_NAME=$(kubectl get pods -n microservices -l app=config-app -o jsonpath='{.items[0].metadata.name}')
if [ -z "$POD_NAME" ]; then
    echo "FAIL: No pod found with label app=config-app"
    exit 1
fi

# Verify environment variables from ConfigMap and Secret are present
ENV_VARS=$(kubectl exec -n microservices "$POD_NAME" -- printenv | grep -E "(APP_NAME|DATABASE_URL)" || true)
if [ -z "$ENV_VARS" ]; then
    echo "FAIL: Expected environment variables from ConfigMap/Secret not found in pod"
    exit 1
fi

echo "PASS: ConfigMaps and Secrets Management validation successful"
