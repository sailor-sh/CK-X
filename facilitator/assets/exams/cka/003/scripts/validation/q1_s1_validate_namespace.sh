#!/bin/bash

# Check if namespace production exists
if kubectl get namespace production &> /dev/null; then
    exit 0
else
    exit 1
fi
