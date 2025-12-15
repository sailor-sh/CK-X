#!/bin/bash
# Q1.5 - Pod has correct resources
# Points: 2

kubectl get pod web-core -n ckad-ns-a -o jsonpath='{.spec.containers[0].resources}' 2>/dev/null | grep -q '{}' && {
  echo "✓ Pod resources configured correctly"
  exit 0
} || {
  echo "✗ Pod resources not configured"
  exit 1
}
