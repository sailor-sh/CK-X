#!/bin/bash
# Q11.5 - Pod uses ConfigMap values
# Points: 2

kubectl get pod config-pod -n configmaps-env -o jsonpath='{.spec.containers[0].env[?(@.name=="APP_COLOR")].valueFrom.configMapKeyRef.name}' 2>/dev/null | grep -q 'app-config' && {
  echo "✓ Pod uses ConfigMap values"
  exit 0
} || {
  echo "✗ Pod not using ConfigMap"
  exit 1
}
