#!/bin/bash
set -e

# Validation for Question 3: Pod Security Standards
echo "Validating Pod Security Standards scenario..."

# Check if namespace exists
if ! kubectl get namespace secure-pods &> /dev/null; then
    echo "FAIL: Namespace 'secure-pods' not found"
    exit 1
fi

# Check if namespace has security labels
SECURITY_LEVEL=$(kubectl get namespace secure-pods -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}')
if [ "$SECURITY_LEVEL" != "restricted" ]; then
    echo "FAIL: Namespace 'secure-pods' should have pod-security.kubernetes.io/enforce=restricted label"
    exit 1
fi

# Check if ServiceAccount exists
if ! kubectl get serviceaccount secure-sa -n secure-pods &> /dev/null; then
    echo "FAIL: ServiceAccount 'secure-sa' not found in namespace secure-pods"
    exit 1
fi

# Check if SecurityContext is properly configured in the pod
if ! kubectl get pod secure-app -n secure-pods &> /dev/null; then
    echo "FAIL: Pod 'secure-app' not found in namespace secure-pods"
    exit 1
fi

# Check pod security context
POD_STATUS=$(kubectl get pod secure-app -n secure-pods -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" != "Running" ]; then
    echo "FAIL: Pod 'secure-app' is not running, status: $POD_STATUS"
    exit 1
fi

# Check if pod runs as non-root
RUN_AS_NON_ROOT=$(kubectl get pod secure-app -n secure-pods -o jsonpath='{.spec.securityContext.runAsNonRoot}')
if [ "$RUN_AS_NON_ROOT" != "true" ]; then
    echo "FAIL: Pod 'secure-app' should run as non-root user"
    exit 1
fi

# Check if readOnlyRootFilesystem is set
READ_ONLY_ROOT=$(kubectl get pod secure-app -n secure-pods -o jsonpath='{.spec.containers[0].securityContext.readOnlyRootFilesystem}')
if [ "$READ_ONLY_ROOT" != "true" ]; then
    echo "FAIL: Pod 'secure-app' should have readOnlyRootFilesystem set to true"
    exit 1
fi

# Check if allowPrivilegeEscalation is disabled
ALLOW_PRIVILEGE_ESCALATION=$(kubectl get pod secure-app -n secure-pods -o jsonpath='{.spec.containers[0].securityContext.allowPrivilegeEscalation}')
if [ "$ALLOW_PRIVILEGE_ESCALATION" != "false" ]; then
    echo "FAIL: Pod 'secure-app' should have allowPrivilegeEscalation set to false"
    exit 1
fi

# Check if capabilities are dropped
CAPABILITIES_DROP=$(kubectl get pod secure-app -n secure-pods -o jsonpath='{.spec.containers[0].securityContext.capabilities.drop[0]}')
if [ "$CAPABILITIES_DROP" != "ALL" ]; then
    echo "FAIL: Pod 'secure-app' should drop ALL capabilities"
    exit 1
fi

echo "PASS: Pod Security Standards validation successful"
