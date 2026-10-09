#!/bin/bash

# Check if DaemonSet log-collector exists in monitoring namespace
if kubectl get daemonset log-collector -n monitoring &> /dev/null; then
    # Check if it's using correct image
    IMAGE=$(kubectl get daemonset log-collector -n monitoring -o jsonpath='{.spec.template.spec.containers[0].image}')
    
    if [[ "$IMAGE" == "fluentd:latest" ]]; then
        exit 0
    else
        exit 1
    fi
else
    exit 1
fi
