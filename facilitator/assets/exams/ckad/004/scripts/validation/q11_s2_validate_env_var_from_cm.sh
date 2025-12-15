#!/bin/bash
# Q11.02 - Pod has MODE env var from ConfigMap
# Points: 4

NS="configmaps-env"
NAME=$(kubectl get pod cm-pod -n "$NS" -o jsonpath='{.spec.containers[0].env[?(@.name=="MODE")].valueFrom.configMapKeyRef.name}' 2>/dev/null)
KEY=$(kubectl get pod cm-pod -n "$NS" -o jsonpath='{.spec.containers[0].env[?(@.name=="MODE")].valueFrom.configMapKeyRef.key}' 2>/dev/null)
if [ "$NAME" = "app-config" ] && [ "$KEY" != "" ]; then
  echo "✓ MODE env var sourced from ConfigMap app-config"
  exit 0
else
  echo "✗ MODE env var not sourced from expected ConfigMap"
  exit 1
fi

