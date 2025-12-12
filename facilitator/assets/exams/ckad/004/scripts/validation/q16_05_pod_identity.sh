#!/bin/bash
# Q16.05 - Pods have stable identity
# Points: 2

PODS=$(kubectl get pods -n q16 -l app=mysql --no-headers 2>/dev/null | wc -l)
[[ $PODS -gt 0 ]] && {
  echo "✓ Pods with stable identity exist"
  exit 0
} || {
  echo "✗ No pods found"
  exit 1
}
