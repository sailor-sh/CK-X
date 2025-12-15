#!/bin/bash
# Q11.4 - ConfigMap has correct data
# Points: 2

kubectl get configmap app-config -n configmaps-env -o jsonpath='{.data}' 2>/dev/null | grep -q 'APP_COLOR' && {
  echo "✓ ConfigMap has correct data"
  exit 0
} || {
  echo "✗ ConfigMap data incorrect"
  exit 1
}
