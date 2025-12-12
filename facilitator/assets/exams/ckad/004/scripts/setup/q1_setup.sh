#!/bin/bash
set -e

NAMESPACE="ckad-ns-a"

# Q1 asks the candidate to create the namespace.
# Ensure setup does NOT create it; instead, ensure a clean slate.
if kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
  echo "Namespace $NAMESPACE exists; deleting to reset state..."
  kubectl delete namespace "$NAMESPACE" --wait=true
fi

echo "✓ Q1 setup complete: Namespace $NAMESPACE is absent (candidate must create it)"
