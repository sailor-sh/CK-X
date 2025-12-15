#!/bin/bash
# Q11.03 - Pod cm-pod is running
# Points: 2

NS="configmaps-env"
PHASE=$(kubectl get pod cm-pod -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PHASE" = "Running" ]; then
  echo "✓ Pod cm-pod is Running"
  exit 0
else
  echo "✗ Pod cm-pod phase is '$PHASE', expected 'Running'"
  exit 1
fi

