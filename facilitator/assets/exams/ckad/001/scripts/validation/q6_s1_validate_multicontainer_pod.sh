#!/bin/bash

# Validate if the pod 'sidecar-pod' exists in the 'troubleshooting' namespace and has containers named 'nginx' and 'sidecar'
POD_EXISTS=$(kubectl get pod sidecar-pod -n troubleshooting -o name 2>/dev/null)

if [ -z "$POD_EXISTS" ]; then
    echo "Error: Pod 'sidecar-pod' does not exist in namespace 'troubleshooting'"
    exit 1
fi

# Verify container names
NGINX_CONTAINER=$(kubectl get pod sidecar-pod -n troubleshooting -o jsonpath='{.spec.containers[?(@.name=="nginx")].name}' 2>/dev/null)
SIDECAR_CONTAINER=$(kubectl get pod sidecar-pod -n troubleshooting -o jsonpath='{.spec.containers[?(@.name=="sidecar")].name}' 2>/dev/null)
SIDECAR_INITCONTAINER=$(kubectl get pod sidecar-pod -n troubleshooting -o jsonpath='{.spec.initContainers[?(@.name=="sidecar")].name}' 2>/dev/null)
SIDECAR_INITCONTAINER_CONDITION=$(kubectl get pod sidecar-pod -n troubleshooting -o jsonpath='{.spec.initContainers[?(@.name=="sidecar")].restartPolicy}' 2>/dev/null)

if [ -n "$NGINX_CONTAINER" ] && [ -n "$SIDECAR_CONTAINER" ]; then
    echo "Success: Pod has both 'nginx' and 'sidecar' containers"
    exit 0
elif [ -n "$NGINX_CONTAINER" ] && [ -n "$SIDECAR_INITCONTAINER" ] && [ "$SIDECAR_INITCONTAINER_CONDITION" = "Always" ]; then
    echo "Success: Pod has 'nginx' container and 'sidecar' init container with restartPolicy 'Always'"
    exit 0
else
    echo "Error: Pod does not have the required container names ('nginx' and 'sidecar')"
    echo "Found containers with names: $(kubectl get pod sidecar-pod -n troubleshooting -o jsonpath='{.spec.containers[*].name}' 2>/dev/null)"
    exit 1
fi