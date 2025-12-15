#!/bin/bash
# Q12.03 - File contains decoded secret
# Points: 3

NS="secrets-volume"
POD="sec-pod"
OUT=$(kubectl exec -n "$NS" "$POD" -- sh -c 'cat /etc/app-secret/api-key 2>/dev/null' 2>/dev/null)
if [ "$OUT" = "123456" ]; then
  echo "✓ Secret file contains expected value"
  exit 0
else
  echo "✗ Secret file content unexpected or not found"
  exit 1
fi

