#!/bin/bash
set -e

# Check if HTTPRoute exists
kubectl get httproute -n gateway || {
    echo "No HTTPRoute found in namespace gateway"
    exit 1
}

# Check app1 path rule
APP1_PATH=$(kubectl get httproute -n gateway -o jsonpath='{.items[0].spec.rules[?(@.matches[0].path.value=="/app1")].matches[0].path.value}')
if [[ "$APP1_PATH" != "/app1" ]]; then
    echo "Missing or incorrect path rule for /app1"
    exit 1
fi

# Check app2 path rule
APP2_PATH=$(kubectl get httproute -n gateway -o jsonpath='{.items[0].spec.rules[?(@.matches[0].path.value=="/app2")].matches[0].path.value}')
if [[ "$APP2_PATH" != "/app2" ]]; then
    echo "Missing or incorrect path rule for /app2"
    exit 1
fi

# Check backend services
APP1_BACKEND=$(kubectl get httproute -n gateway -o jsonpath='{.items[0].spec.rules[?(@.matches[0].path.value=="/app1")].backendRefs[0].name}')
if [[ "$APP1_BACKEND" != "app1-svc" ]]; then
    echo "Incorrect backend service for /app1. Expected app1-svc, got $APP1_BACKEND"
    exit 1
fi

APP2_BACKEND=$(kubectl get httproute -n gateway -o jsonpath='{.items[0].spec.rules[?(@.matches[0].path.value=="/app2")].backendRefs[0].name}')
if [[ "$APP2_BACKEND" != "app2-svc" ]]; then
    echo "Incorrect backend service for /app2. Expected app2-svc, got $APP2_BACKEND"
    exit 1
fi

# Check backend ports
APP1_PORT=$(kubectl get httproute -n gateway -o jsonpath='{.items[0].spec.rules[?(@.matches[0].path.value=="/app1")].backendRefs[0].port}')
APP2_PORT=$(kubectl get httproute -n gateway -o jsonpath='{.items[0].spec.rules[?(@.matches[0].path.value=="/app2")].backendRefs[0].port}')
if [[ "$APP1_PORT" != "8080" ]] || [[ "$APP2_PORT" != "8080" ]]; then
    echo "Incorrect backend ports. Expected 8080 for both services"
    exit 1
fi

echo "HTTPRoute validation successful"
exit 0 