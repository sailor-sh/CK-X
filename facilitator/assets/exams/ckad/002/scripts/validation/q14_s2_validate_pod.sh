#!/bin/bash

# Validate that the pod exists with init container
POD=$(kubectl get pod app-with-init -n init-containers -o jsonpath='{.metadata.name}' 2>/dev/null)

if [[ "$POD" == "app-with-init" ]]; then
    # Pod exists, now check init container
    
    # Check main container image
    MAIN_CONTAINER_IMAGE=$(kubectl get pod app-with-init -n init-containers -o jsonpath='{.spec.containers[0].image}' 2>/dev/null)
    
    # Check init container existence
    INIT_CONTAINER=$(kubectl get pod app-with-init -n init-containers -o jsonpath='{.spec.initContainers[0].name}' 2>/dev/null)
    
    # Check init container image
    INIT_CONTAINER_IMAGE=$(kubectl get pod app-with-init -n init-containers -o jsonpath='{.spec.initContainers[0].image}' 2>/dev/null)
    
    # Check init container command
    INIT_CONTAINER_COMMAND=$(kubectl get pod app-with-init -n init-containers -o jsonpath='{.spec.initContainers[0].command}' 2>/dev/null)
    
    if [[ "$MAIN_CONTAINER_IMAGE" == "nginx" && 
          "$INIT_CONTAINER_IMAGE" == "busybox" && 
          "$INIT_CONTAINER_COMMAND" == *"nslookup myservice.init-containers.svc.cluster.local"* ]]; then
        # Pod and init container are configured correctly
        exit 0
    else
        echo "Pod 'app-with-init' does not have correct configuration."
        echo "Found main container image: $MAIN_CONTAINER_IMAGE (expected: nginx)"
        echo "Found init container: $INIT_CONTAINER"
        echo "Found init container image: $INIT_CONTAINER_IMAGE (expected: busybox)"
        echo "Found init container command: $INIT_CONTAINER_COMMAND (should include 'nslookup myservice.init-containers.svc.cluster.local')"
        exit 1
    fi
else
    # Pod does not exist
    echo "Pod 'app-with-init' does not exist in the 'init-containers' namespace"
    exit 1
fi 