#!/bin/bash
# Q22.06 - Both deployments running
# Points: 2

PODS=$(kubectl get pods -n q22 --no-headers 2>/dev/null | wc -l)
[[ $PODS -gt 1 ]] && {
  echo "✓ Pods running"
  exit 0
} || {
  echo "✗ Missing pods"
  exit 1
}
