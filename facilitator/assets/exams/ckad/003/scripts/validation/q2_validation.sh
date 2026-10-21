#!/bin/bash
set -e

# Validation for Question 2: Service Mesh Integration
echo "Validating Service Mesh Integration scenario..."

# Check if namespace exists
if ! kubectl get namespace microservices &> /dev/null; then
    echo "FAIL: Namespace 'microservices' not found"
    exit 1
fi

# Check if frontend service exists
if ! kubectl get service frontend-service -n microservices &> /dev/null; then
    echo "FAIL: Service 'frontend-service' not found in namespace microservices"
    exit 1
fi

# Check if backend service exists
if ! kubectl get service backend-service -n microservices &> /dev/null; then
    echo "FAIL: Service 'backend-service' not found in namespace microservices"
    exit 1
fi

# Check if frontend deployment exists and is available
if ! kubectl get deployment frontend -n microservices &> /dev/null; then
    echo "FAIL: Deployment 'frontend' not found in namespace microservices"
    exit 1
fi

# Check if backend deployment exists and is available
if ! kubectl get deployment backend -n microservices &> /dev/null; then
    echo "FAIL: Deployment 'backend' not found in namespace microservices"
    exit 1
fi

# Check deployment readiness
FRONTEND_READY=$(kubectl get deployment frontend -n microservices -o jsonpath='{.status.readyReplicas}')
BACKEND_READY=$(kubectl get deployment backend -n microservices -o jsonpath='{.status.readyReplicas}')

if [ "$FRONTEND_READY" != "2" ]; then
    echo "FAIL: Frontend deployment should have 2 ready replicas, found: $FRONTEND_READY"
    exit 1
fi

if [ "$BACKEND_READY" != "2" ]; then
    echo "FAIL: Backend deployment should have 2 ready replicas, found: $BACKEND_READY"
    exit 1
fi

echo "PASS: Service Mesh Integration validation successful"
