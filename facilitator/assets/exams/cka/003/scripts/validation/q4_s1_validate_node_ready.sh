#!/bin/bash

# Check if all nodes are in Ready state
NOT_READY_NODES=$(kubectl get nodes --no-headers | grep -v " Ready " | wc -l)

if [[ $NOT_READY_NODES -eq 0 ]]; then
    exit 0
else
    exit 1
fi
