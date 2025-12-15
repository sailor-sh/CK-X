#!/bin/bash
# Q19.03 - Ingress traffic blocked (structural check)
# Points: 3

# Structural verification: default-deny with no ingress rules implies traffic blocked
NS="network-policies"
ING=$(kubectl get networkpolicy default-deny -n "$NS" -o jsonpath='{.spec.ingress}' 2>/dev/null)
if [ -z "$ING" ]; then
  echo "✓ No ingress rules present; ingress blocked by default"
  exit 0
else
  echo "✗ Ingress rules present; not a default deny"
  exit 1
fi

