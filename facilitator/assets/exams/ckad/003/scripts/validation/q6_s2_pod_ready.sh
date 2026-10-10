#!/bin/bash
# Validator for Q6 - Pod Readiness
# Checks if pod 'pod6' has a Ready condition of True.
STATUS=$(kubectl get pod pod6 -n readiness -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
if [ "$STATUS" == "True" ]; then
  exit 0
else
  exit 1
fi
