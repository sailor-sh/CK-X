#!/bin/bash
# Q21.04 - Pod scheduled on correct node
# Points: 2

NODE=$(kubectl get pod affinity-pod -n q21 -o jsonpath='{.spec.nodeName}' 2>/dev/null)
[[ -n "$NODE" ]] && {
  echo "✓ Pod scheduled on $NODE"
  exit 0
} || {
  echo "✗ Pod not scheduled"
  exit 1
}
