#!/bin/bash
# Q13.02 - Env vars from ConfigMap
# Points: 2

ENVFROM=$(kubectl get pod env-pod -n q13 -o jsonpath='{.spec.containers[0].envFrom}' 2>/dev/null)
[[ -n "$ENVFROM" ]] && {
  echo "✓ envFrom set"
  exit 0
} || {
  echo "✗ No envFrom"
  exit 1
}
