#!/bin/bash
# Q17.01 - Pod ready-web exists
# Points: 2

NS="readiness-probes"
kubectl get pod ready-web -n "$NS" >/dev/null 2>&1 && {
  echo "✓ Pod ready-web exists in $NS"
  exit 0
} || {
  echo "✗ Pod ready-web not found in $NS"
  exit 1
}

