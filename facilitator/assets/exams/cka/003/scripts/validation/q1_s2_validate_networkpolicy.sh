#!/bin/bash

# Check if NetworkPolicy backend-netpol exists in production namespace
if kubectl get networkpolicy backend-netpol -n production &> /dev/null; then
    # Check if it has correct ingress rules
    INGRESS_CHECK=$(kubectl get networkpolicy backend-netpol -n production -o yaml | grep -A5 "from:" | grep "app: frontend")
    if [[ -n "$INGRESS_CHECK" ]]; then
        exit 0
    else
        exit 1
    fi
else
    exit 1
fi
