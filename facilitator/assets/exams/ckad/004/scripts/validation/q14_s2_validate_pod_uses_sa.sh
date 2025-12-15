#!/bin/bash
# Q14.02 - Pod uses correct ServiceAccount
# Points: 4

NS="service-accounts"
SA=$(kubectl get pod backend-pod -n "$NS" -o jsonpath='{.spec.serviceAccountName}' 2>/dev/null)
if [ "$SA" = "backend-sa" ]; then
  echo "✓ Pod backend-pod uses ServiceAccount backend-sa"
  exit 0
else
  echo "✗ Pod serviceAccountName is '$SA', expected 'backend-sa'"
  exit 1
fi

