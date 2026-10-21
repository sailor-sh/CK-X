#!/bin/bash
set -e

# Validation for Question 4: Secrets Management and Encryption
echo "Validating Secrets Management and Encryption scenario..."

# Check if namespace exists
if ! kubectl get namespace secrets-demo &> /dev/null; then
    echo "FAIL: Namespace 'secrets-demo' not found"
    exit 1
fi

# Check if Secret exists
if ! kubectl get secret database-credentials -n secrets-demo &> /dev/null; then
    echo "FAIL: Secret 'database-credentials' not found in namespace secrets-demo"
    exit 1
fi

# Check if TLS Secret exists
if ! kubectl get secret tls-secret -n secrets-demo &> /dev/null; then
    echo "FAIL: Secret 'tls-secret' not found in namespace secrets-demo"
    exit 1
fi

# Check if deployment exists
if ! kubectl get deployment app-with-secrets -n secrets-demo &> /dev/null; then
    echo "FAIL: Deployment 'app-with-secrets' not found in namespace secrets-demo"
    exit 1
fi

# Check if deployment is ready
READY_REPLICAS=$(kubectl get deployment app-with-secrets -n secrets-demo -o jsonpath='{.status.readyReplicas}')
if [ "$READY_REPLICAS" != "1" ]; then
    echo "FAIL: Deployment 'app-with-secrets' should have 1 ready replica, found: $READY_REPLICAS"
    exit 1
fi

# Check if pod is using secrets
POD_NAME=$(kubectl get pods -n secrets-demo -l app=app-with-secrets -o jsonpath='{.items[0].metadata.name}')
if [ -z "$POD_NAME" ]; then
    echo "FAIL: No pod found with label app=app-with-secrets"
    exit 1
fi

# Check if secret is mounted as volume
VOLUME_MOUNTS=$(kubectl get pod "$POD_NAME" -n secrets-demo -o jsonpath='{.spec.containers[0].volumeMounts[*].name}')
if [[ "$VOLUME_MOUNTS" != *"tls-volume"* ]]; then
    echo "FAIL: TLS secret not mounted as volume in pod"
    exit 1
fi

# Check if secret is used as environment variables
ENV_FROM=$(kubectl get pod "$POD_NAME" -n secrets-demo -o jsonpath='{.spec.containers[0].envFrom[*].secretRef.name}')
if [[ "$ENV_FROM" != *"database-credentials"* ]]; then
    echo "FAIL: Database credentials secret not used as environment variables"
    exit 1
fi

# Verify secret type for TLS
SECRET_TYPE=$(kubectl get secret tls-secret -n secrets-demo -o jsonpath='{.type}')
if [ "$SECRET_TYPE" != "kubernetes.io/tls" ]; then
    echo "FAIL: Secret 'tls-secret' should be of type kubernetes.io/tls, found: $SECRET_TYPE"
    exit 1
fi

echo "PASS: Secrets Management and Encryption validation successful"
