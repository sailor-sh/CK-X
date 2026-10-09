#!/bin/bash

# Check if StatefulSet mysql-cluster exists in database namespace
if kubectl get statefulset mysql-cluster -n database &> /dev/null; then
    # Check if it has 2 replicas
    REPLICAS=$(kubectl get statefulset mysql-cluster -n database -o jsonpath='{.spec.replicas}')
    # Check if pods are running
    READY_REPLICAS=$(kubectl get statefulset mysql-cluster -n database -o jsonpath='{.status.readyReplicas}')
    
    if [[ "$REPLICAS" == "2" && "$READY_REPLICAS" == "2" ]]; then
        exit 0
    else
        exit 1
    fi
else
    exit 1
fi
