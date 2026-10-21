#!/bin/bash
# Validator for Q6 - Pod Existence
# Checks if pod 'pod6' exists in namespace 'readiness'.
kubectl get pod pod6 -n readiness > /dev/null 2>&1
