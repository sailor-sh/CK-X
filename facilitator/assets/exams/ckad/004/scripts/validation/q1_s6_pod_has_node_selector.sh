#!/bin/bash
# Q1.6 - Pod has node selector
# Points: 2

kubectl get pod web-core -n ckad-ns-a -o jsonpath='{.spec.nodeSelector}' 2>/dev/null | grep -q '{}' && {
  echo "✓ Pod node selector configured"
  exit 0
} || {
  echo "✗ Pod node selector missing"
  exit 1
}
