#!/bin/bash
# Q04.02 - ConfigMap has app.properties
# Points: 2

KEY=$(kubectl get configmap app-config -n q04 -o jsonpath='{.data.app\.properties}' 2>/dev/null)
[[ -n "$KEY" ]] && {
  echo "✓ ConfigMap has app.properties"
  exit 0
} || {
  echo "✗ app.properties key not found"
  exit 1
}
