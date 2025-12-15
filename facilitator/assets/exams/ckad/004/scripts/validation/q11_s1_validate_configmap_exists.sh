#!/bin/bash
# Q11.01 - ConfigMap app-config exists
# Points: 2

NS="configmaps-env"
kubectl get configmap app-config -n "$NS" >/dev/null 2>&1 && {
  echo "✓ ConfigMap app-config exists in $NS"
  exit 0
} || {
  echo "✗ ConfigMap app-config not found in $NS"
  exit 1
}

