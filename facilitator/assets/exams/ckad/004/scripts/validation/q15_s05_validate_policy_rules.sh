#!/bin/bash
# Q15.05 - Policy allows correct traffic
# Points: 2

RULES=$(kubectl get networkpolicy -n q15 -o jsonpath='{.items[0].spec.ingress}' 2>/dev/null)
[[ -n "$RULES" ]] && {
  echo "✓ Ingress rules configured"
  exit 0
} || {
  echo "✗ No ingress rules"
  exit 1
}
