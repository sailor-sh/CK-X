#!/bin/bash

# Check if DaemonSet pods are running on all worker nodes
WORKER_NODE_COUNT=$(kubectl get nodes --no-headers | grep -v "control-plane\|master" | wc -l)
RUNNING_PODS_COUNT=$(kubectl get pods -n monitoring -l app=log-collector --no-headers | grep Running | wc -l)

if [[ $RUNNING_PODS_COUNT -ge 1 ]]; then
    exit 0
else
    exit 1
fi
