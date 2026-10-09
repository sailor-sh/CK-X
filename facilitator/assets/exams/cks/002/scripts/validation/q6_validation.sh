#!/bin/bash
set -e

# Validation for Question 6: Admission Controllers and OPA
echo "Validating Admission Controllers and OPA scenario..."

# Check if namespace exists
if ! kubectl get namespace policy-demo &> /dev/null; then
    echo "FAIL: Namespace 'policy-demo' not found"
    exit 1
fi

# Check if namespace has required labels
NAMESPACE_LABELS=$(kubectl get namespace policy-demo -o jsonpath='{.metadata.labels}')
if [[ "$NAMESPACE_LABELS" != *"security-level"* ]]; then
    echo "FAIL: Namespace 'policy-demo' should have 'security-level' label"
    exit 1
fi

# Check if compliant deployment exists
if ! kubectl get deployment compliant-app -n policy-demo &> /dev/null; then
    echo "FAIL: Deployment 'compliant-app' not found in namespace policy-demo"
    exit 1
fi

# Check if deployment is ready
READY_REPLICAS=$(kubectl get deployment compliant-app -n policy-demo -o jsonpath='{.status.readyReplicas}')
if [ "$READY_REPLICAS" != "1" ]; then
    echo "FAIL: Deployment 'compliant-app' should have 1 ready replica, found: $READY_REPLICAS"
    exit 1
fi

# Get pod to check compliance
POD_NAME=$(kubectl get pods -n policy-demo -l app=compliant-app -o jsonpath='{.items[0].metadata.name}')
if [ -z "$POD_NAME" ]; then
    echo "FAIL: No pod found with label app=compliant-app"
    exit 1
fi

# Check if pod has required labels
POD_LABELS=$(kubectl get pod "$POD_NAME" -n policy-demo -o jsonpath='{.metadata.labels}')
if [[ "$POD_LABELS" != *"version"* ]]; then
    echo "FAIL: Pod should have 'version' label as required by policy"
    exit 1
fi

# Check if pod has resource limits (policy compliance)
CPU_LIMITS=$(kubectl get pod "$POD_NAME" -n policy-demo -o jsonpath='{.spec.containers[0].resources.limits.cpu}')
MEMORY_LIMITS=$(kubectl get pod "$POD_NAME" -n policy-demo -o jsonpath='{.spec.containers[0].resources.limits.memory}')

if [ -z "$CPU_LIMITS" ] || [ -z "$MEMORY_LIMITS" ]; then
    echo "FAIL: Pod should have resource limits set as required by policy"
    exit 1
fi

# Check if pod runs as non-root (policy requirement)
RUN_AS_NON_ROOT=$(kubectl get pod "$POD_NAME" -n policy-demo -o jsonpath='{.spec.securityContext.runAsNonRoot}')
if [ "$RUN_AS_NON_ROOT" != "true" ]; then
    echo "FAIL: Pod should run as non-root as required by policy"
    exit 1
fi

# Check if pod has security context configured
SECURITY_CONTEXT=$(kubectl get pod "$POD_NAME" -n policy-demo -o jsonpath='{.spec.containers[0].securityContext.readOnlyRootFilesystem}')
if [ "$SECURITY_CONTEXT" != "true" ]; then
    echo "FAIL: Pod should have readOnlyRootFilesystem=true as required by policy"
    exit 1
fi

echo "PASS: Admission Controllers and OPA validation successful"
