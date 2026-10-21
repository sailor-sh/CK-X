#!/bin/bash
set -e

# Validation for Question 6: Resource Quotas and Limits
echo "Validating Resource Quotas and Limits scenario..."

# Check if namespace exists
if ! kubectl get namespace resource-limited &> /dev/null; then
    echo "FAIL: Namespace 'resource-limited' not found"
    exit 1
fi

# Check if ResourceQuota exists
if ! kubectl get resourcequota compute-quota -n resource-limited &> /dev/null; then
    echo "FAIL: ResourceQuota 'compute-quota' not found in namespace resource-limited"
    exit 1
fi

# Check if LimitRange exists
if ! kubectl get limitrange compute-limits -n resource-limited &> /dev/null; then
    echo "FAIL: LimitRange 'compute-limits' not found in namespace resource-limited"
    exit 1
fi

# Check if deployment exists
if ! kubectl get deployment limited-app -n resource-limited &> /dev/null; then
    echo "FAIL: Deployment 'limited-app' not found in namespace resource-limited"
    exit 1
fi

# Check if deployment is ready
READY_REPLICAS=$(kubectl get deployment limited-app -n resource-limited -o jsonpath='{.status.readyReplicas}')
if [ "$READY_REPLICAS" != "2" ]; then
    echo "FAIL: Deployment 'limited-app' should have 2 ready replicas, found: $READY_REPLICAS"
    exit 1
fi

# Get pod name to check resource limits
POD_NAME=$(kubectl get pods -n resource-limited -l app=limited-app -o jsonpath='{.items[0].metadata.name}')
if [ -z "$POD_NAME" ]; then
    echo "FAIL: No pod found with label app=limited-app"
    exit 1
fi

# Check if resource requests and limits are set
CPU_REQUESTS=$(kubectl get pod "$POD_NAME" -n resource-limited -o jsonpath='{.spec.containers[0].resources.requests.cpu}')
MEMORY_REQUESTS=$(kubectl get pod "$POD_NAME" -n resource-limited -o jsonpath='{.spec.containers[0].resources.requests.memory}')
CPU_LIMITS=$(kubectl get pod "$POD_NAME" -n resource-limited -o jsonpath='{.spec.containers[0].resources.limits.cpu}')
MEMORY_LIMITS=$(kubectl get pod "$POD_NAME" -n resource-limited -o jsonpath='{.spec.containers[0].resources.limits.memory}')

if [ -z "$CPU_REQUESTS" ] || [ -z "$MEMORY_REQUESTS" ]; then
    echo "FAIL: Resource requests not set for pod containers"
    exit 1
fi

if [ -z "$CPU_LIMITS" ] || [ -z "$MEMORY_LIMITS" ]; then
    echo "FAIL: Resource limits not set for pod containers"
    exit 1
fi

# Check ResourceQuota usage
QUOTA_USED=$(kubectl describe resourcequota compute-quota -n resource-limited | grep -c "Used:" || true)
if [ "$QUOTA_USED" -eq 0 ]; then
    echo "FAIL: ResourceQuota not being enforced"
    exit 1
fi

echo "PASS: Resource Quotas and Limits validation successful"
