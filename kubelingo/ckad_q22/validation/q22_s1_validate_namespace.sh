#!/bin/bash

# Validate that namespace 'platform' exists
NAMESPACE="platform"

if kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
  echo "Success: Namespace '$NAMESPACE' exists"
  exit 0
else
  echo "Error: Namespace '$NAMESPACE' does not exist"
  exit 1
fi

