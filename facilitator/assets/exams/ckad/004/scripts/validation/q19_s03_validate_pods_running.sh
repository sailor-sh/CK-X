#!/bin/bash
# Q19.03 - Pods running on nodes
# Points: 2

PODS=$(kubectl get pods -n q19 -l app=logger --no-headers 2>/dev/null | wc -l)
[[ $PODS -gt 0 ]] && {
  echo "✓ Pods running on nodes"
  exit 0
} || {
  echo "✗ No pods found"
  exit 1
}
