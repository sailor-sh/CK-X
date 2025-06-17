#!/bin/bash
set -e

# Validation for Question 2: Network Policies
echo "Validating Network Policies scenario..."

# Check if namespace exists
if ! kubectl get namespace secure-net &> /dev/null; then
    echo "FAIL: Namespace 'secure-net' not found"
    exit 1
fi

# Check if NetworkPolicy exists
if ! kubectl get networkpolicy deny-all -n secure-net &> /dev/null; then
    echo "FAIL: NetworkPolicy 'deny-all' not found in namespace secure-net"
    exit 1
fi

if ! kubectl get networkpolicy allow-frontend -n secure-net &> /dev/null; then
    echo "FAIL: NetworkPolicy 'allow-frontend' not found in namespace secure-net"
    exit 1
fi

if ! kubectl get networkpolicy allow-backend -n secure-net &> /dev/null; then
    echo "FAIL: NetworkPolicy 'allow-backend' not found in namespace secure-net"
    exit 1
fi

# Check if pods exist
if ! kubectl get pod frontend -n secure-net &> /dev/null; then
    echo "FAIL: Pod 'frontend' not found in namespace secure-net"
    exit 1
fi

if ! kubectl get pod backend -n secure-net &> /dev/null; then
    echo "FAIL: Pod 'backend' not found in namespace secure-net"
    exit 1
fi

if ! kubectl get pod database -n secure-net &> /dev/null; then
    echo "FAIL: Pod 'database' not found in namespace secure-net"
    exit 1
fi

# Check if pods are running
FRONTEND_STATUS=$(kubectl get pod frontend -n secure-net -o jsonpath='{.status.phase}')
BACKEND_STATUS=$(kubectl get pod backend -n secure-net -o jsonpath='{.status.phase}')
DATABASE_STATUS=$(kubectl get pod database -n secure-net -o jsonpath='{.status.phase}')

if [ "$FRONTEND_STATUS" != "Running" ]; then
    echo "FAIL: Pod 'frontend' is not running, status: $FRONTEND_STATUS"
    exit 1
fi

if [ "$BACKEND_STATUS" != "Running" ]; then
    echo "FAIL: Pod 'backend' is not running, status: $BACKEND_STATUS"
    exit 1
fi

if [ "$DATABASE_STATUS" != "Running" ]; then
    echo "FAIL: Pod 'database' is not running, status: $DATABASE_STATUS"
    exit 1
fi

# Check NetworkPolicy specifications
DENY_ALL_SPEC=$(kubectl get networkpolicy deny-all -n secure-net -o jsonpath='{.spec.podSelector}')
if [ "$DENY_ALL_SPEC" != "{}" ]; then
    echo "FAIL: NetworkPolicy 'deny-all' should select all pods (empty podSelector)"
    exit 1
fi

echo "PASS: Network Policies validation successful"
