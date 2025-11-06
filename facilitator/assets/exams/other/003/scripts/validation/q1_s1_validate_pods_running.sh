#!/bin/bash

# Validate if the pods of deployment 'broken-app' are running in the 'troubleshooting' namespace
READY_PODS=$(kubectl get deployment broken-app -n troubleshooting -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
TOTAL_PODS=$(kubectl get deployment broken-app -n troubleshooting -o jsonpath='{.status.replicas}' 2>/dev/null)

if [ -z "$READY_PODS" ]; then
    READY_PODS=0
fi

if [ -z "$TOTAL_PODS" ]; then
    echo "Error: Deployment 'broken-app' does not exist in namespace 'troubleshooting'"
    exit 1
fi

if [ "$READY_PODS" -eq "$TOTAL_PODS" ] && [ "$READY_PODS" -gt 0 ]; then
    echo "Success: All pods in deployment 'broken-app' are running ($READY_PODS/$TOTAL_PODS)"
    exit 0
else
    echo "Error: Not all pods in deployment 'broken-app' are running ($READY_PODS/$TOTAL_PODS)"
    exit 1
fi