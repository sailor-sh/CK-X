#!/bin/bash
set -e

# Check if Gateway exists
kubectl get gateway main-gateway -n gateway || {
    echo "Gateway main-gateway not found in namespace gateway"
    exit 1
}

# Check if Gateway is listening on port 80
PORT=$(kubectl get gateway main-gateway -n gateway -o jsonpath='{.spec.listeners[0].port}')
if [[ "$PORT" != "80" ]]; then
    echo "Gateway is not listening on port 80. Current port: $PORT"
    exit 1
fi

# Check protocol
PROTOCOL=$(kubectl get gateway main-gateway -n gateway -o jsonpath='{.spec.listeners[0].protocol}')
if [[ "$PROTOCOL" != "HTTP" ]]; then
    echo "Gateway is not using HTTP protocol. Current protocol: $PROTOCOL"
    exit 1
fi

# Check if Gateway is ready
# READY_STATUS=$(kubectl get gateway main-gateway -n gateway -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
# if [[ "$READY_STATUS" != "True" ]]; then
#     echo "Gateway is not ready. Current status: $READY_STATUS"
#     exit 1
# fi

echo "Gateway validation successful"
exit 0 