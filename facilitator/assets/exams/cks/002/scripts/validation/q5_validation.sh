#!/bin/bash
set -e

# Validation for Question 5: Image Security and Scanning
echo "Validating Image Security and Scanning scenario..."

# Check if namespace exists
if ! kubectl get namespace image-security &> /dev/null; then
    echo "FAIL: Namespace 'image-security' not found"
    exit 1
fi

# Check if ImagePolicy exists (if supported by the cluster)
# Note: This might not be available in all clusters
# if ! kubectl get imagepolicy secure-images &> /dev/null; then
#     echo "WARN: ImagePolicy 'secure-images' not found (may not be supported)"
# fi

# Check if deployment with secure image exists
if ! kubectl get deployment secure-app -n image-security &> /dev/null; then
    echo "FAIL: Deployment 'secure-app' not found in namespace image-security"
    exit 1
fi

# Check if deployment is ready
READY_REPLICAS=$(kubectl get deployment secure-app -n image-security -o jsonpath='{.status.readyReplicas}')
if [ "$READY_REPLICAS" != "1" ]; then
    echo "FAIL: Deployment 'secure-app' should have 1 ready replica, found: $READY_REPLICAS"
    exit 1
fi

# Check if the image is from a trusted registry
POD_NAME=$(kubectl get pods -n image-security -l app=secure-app -o jsonpath='{.items[0].metadata.name}')
if [ -z "$POD_NAME" ]; then
    echo "FAIL: No pod found with label app=secure-app"
    exit 1
fi

IMAGE_NAME=$(kubectl get pod "$POD_NAME" -n image-security -o jsonpath='{.spec.containers[0].image}')
# Check if image has a specific tag (not latest)
if [[ "$IMAGE_NAME" == *":latest" ]]; then
    echo "FAIL: Pod should not use 'latest' tag, found image: $IMAGE_NAME"
    exit 1
fi

# Check if pod has security context configured
SECURITY_CONTEXT=$(kubectl get pod "$POD_NAME" -n image-security -o jsonpath='{.spec.containers[0].securityContext}')
if [ -z "$SECURITY_CONTEXT" ]; then
    echo "FAIL: Pod container should have securityContext configured"
    exit 1
fi

# Check if pod runs as non-root
RUN_AS_NON_ROOT=$(kubectl get pod "$POD_NAME" -n image-security -o jsonpath='{.spec.securityContext.runAsNonRoot}')
if [ "$RUN_AS_NON_ROOT" != "true" ]; then
    echo "FAIL: Pod should run as non-root user"
    exit 1
fi

# Check if imagePullPolicy is Always
IMAGE_PULL_POLICY=$(kubectl get pod "$POD_NAME" -n image-security -o jsonpath='{.spec.containers[0].imagePullPolicy}')
if [ "$IMAGE_PULL_POLICY" != "Always" ]; then
    echo "FAIL: Pod should have imagePullPolicy set to Always, found: $IMAGE_PULL_POLICY"
    exit 1
fi

echo "PASS: Image Security and Scanning validation successful"
