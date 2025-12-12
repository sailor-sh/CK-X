#!/bin/bash
# Q22.05 - Cache pod scheduled correctly
# Points: 2

NODE=$(kubectl get pod cache-pod -n q22 -o jsonpath='{.spec.nodeName}' 2>/dev/null)
[[ -n "$NODE" ]] && {
  echo "✓ Pod scheduled on $NODE"
  exit 0
} || {
  echo "✗ Pod not scheduled"
  exit 1
}
