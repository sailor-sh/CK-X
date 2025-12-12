#!/bin/bash
# Q13.03 - Env vars from Secret
# Points: 2

ENV=$(kubectl get pod env-pod -n q13 -o jsonpath='{.spec.containers[0].env}' 2>/dev/null)
[[ -n "$ENV" ]] && {
  echo "✓ Env vars set"
  exit 0
} || {
  echo "✗ No env vars"
  exit 1
}
