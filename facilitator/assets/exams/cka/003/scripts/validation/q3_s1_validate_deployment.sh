#!/bin/bash

# Check if deployment web-server exists in web-app namespace
if kubectl get deployment web-server -n web-app &> /dev/null; then
    # Check if it has 2 replicas
    REPLICAS=$(kubectl get deployment web-server -n web-app -o jsonpath='{.spec.replicas}')
    # Check if it uses correct image
    IMAGE=$(kubectl get deployment web-server -n web-app -o jsonpath='{.spec.template.spec.containers[0].image}')
    # Check resource requests and limits
    CPU_REQUEST=$(kubectl get deployment web-server -n web-app -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}')
    MEM_REQUEST=$(kubectl get deployment web-server -n web-app -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}')
    
    if [[ "$REPLICAS" == "2" && "$IMAGE" == "nginx:1.20" && "$CPU_REQUEST" == "100m" && "$MEM_REQUEST" == "128Mi" ]]; then
        exit 0
    else
        exit 1
    fi
else
    exit 1
fi
