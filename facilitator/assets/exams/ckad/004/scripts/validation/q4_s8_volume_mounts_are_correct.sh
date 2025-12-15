#!/bin/bash
# Q4.8 - Volume mounts are correct
# Points: 2

kubectl get pod logger-pod -n sidecar-logging -o jsonpath='{.spec.containers[*].volumeMounts[*].mountPath}' 2>/dev/null | grep -q '/var/log' && {
  echo "✓ Volume mounts are correct"
  exit 0
} || {
  echo "✗ Volume mounts incorrect"
  exit 1
}
