#!/bin/bash

# Check if service web-service exists in web-app namespace
if kubectl get service web-service -n web-app &> /dev/null; then
    # Check if it's ClusterIP type and targets correct port
    TYPE=$(kubectl get service web-service -n web-app -o jsonpath='{.spec.type}')
    PORT=$(kubectl get service web-service -n web-app -o jsonpath='{.spec.ports[0].port}')
    
    if [[ "$TYPE" == "ClusterIP" && "$PORT" == "80" ]]; then
        exit 0
    else
        exit 1
    fi
else
    exit 1
fi
