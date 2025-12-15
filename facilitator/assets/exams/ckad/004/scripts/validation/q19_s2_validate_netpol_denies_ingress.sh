#!/bin/bash
# Q19.02 - NetworkPolicy denies ingress (no ingress rules)
# Points: 4

NS="network-policies"
ING=$(kubectl get networkpolicy default-deny -n "$NS" -o jsonpath='{.spec.ingress}' 2>/dev/null)
PT=$(kubectl get networkpolicy default-deny -n "$NS" -o jsonpath='{.spec.policyTypes[*]}' 2>/dev/null)
if echo "$PT" | grep -q "Ingress" && [ -z "$ING" ]; then
  echo "✓ Policy denies ingress (no ingress rules defined)"
  exit 0
else
  echo "✗ Policy may not deny ingress (policyTypes=$PT, ingress=$ING)"
  exit 1
fi

