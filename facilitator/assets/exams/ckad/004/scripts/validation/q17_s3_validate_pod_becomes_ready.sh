#!/bin/bash
# Q17.03 - Pod becomes Ready
# Points: 2

NS="readiness-probes"
READY=$(kubectl get pod ready-web -n "$NS" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
if echo "$READY" | grep -q "True"; then
  echo "✓ Pod ready-web is Ready"
  exit 0
else
  echo "✗ Pod ready-web is not Ready"
  exit 1
fi

