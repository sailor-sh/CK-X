#!/bin/bash
# Q04.01 - ConfigMap app-config exists
# Points: 2

kubectl get configmap app-config -n q04 >/dev/null 2>&1 && {
  echo "✓ ConfigMap app-config exists"
  exit 0
} || {
  echo "✗ ConfigMap app-config not found"
  exit 1
}
