#!/bin/bash
set -e

# Validation for Question 5: Health Checks and Readiness Probes
echo "Validating Health Checks and Readiness Probes scenario..."

# Check if namespace exists
if ! kubectl get namespace microservices &> /dev/null; then
    echo "FAIL: Namespace 'microservices' not found"
    exit 1
fi

# Check if deployment exists
if ! kubectl get deployment health-app -n microservices &> /dev/null; then
    echo "FAIL: Deployment 'health-app' not found in namespace microservices"
    exit 1
fi

# Check if deployment is ready
READY_REPLICAS=$(kubectl get deployment health-app -n microservices -o jsonpath='{.status.readyReplicas}')
if [ "$READY_REPLICAS" != "2" ]; then
    echo "FAIL: Deployment 'health-app' should have 2 ready replicas, found: $READY_REPLICAS"
    exit 1
fi

# Check if service exists
if ! kubectl get service health-service -n microservices &> /dev/null; then
    echo "FAIL: Service 'health-service' not found in namespace microservices"
    exit 1
fi

# Get pod name to check probes
POD_NAME=$(kubectl get pods -n microservices -l app=health-app -o jsonpath='{.items[0].metadata.name}')
if [ -z "$POD_NAME" ]; then
    echo "FAIL: No pod found with label app=health-app"
    exit 1
fi

# Check if livenessProbe is configured
LIVENESS_PROBE=$(kubectl get pod "$POD_NAME" -n microservices -o jsonpath='{.spec.containers[0].livenessProbe}')
if [ -z "$LIVENESS_PROBE" ]; then
    echo "FAIL: Liveness probe not configured for health-app"
    exit 1
fi

# Check if readinessProbe is configured
READINESS_PROBE=$(kubectl get pod "$POD_NAME" -n microservices -o jsonpath='{.spec.containers[0].readinessProbe}')
if [ -z "$READINESS_PROBE" ]; then
    echo "FAIL: Readiness probe not configured for health-app"
    exit 1
fi

# Check if all pods are ready
READY_COUNT=$(kubectl get pods -n microservices -l app=health-app -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' | grep -o "True" | wc -l)
TOTAL_COUNT=$(kubectl get pods -n microservices -l app=health-app --no-headers | wc -l)

if [ "$READY_COUNT" != "$TOTAL_COUNT" ]; then
    echo "FAIL: Not all pods are ready. Ready: $READY_COUNT, Total: $TOTAL_COUNT"
    exit 1
fi

echo "PASS: Health Checks and Readiness Probes validation successful"
