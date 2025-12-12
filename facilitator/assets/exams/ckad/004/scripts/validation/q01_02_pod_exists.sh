#!/bin/bash
# Q01.02 - Pod web-core exists in namespace
# Points: 2

kubectl get pod web-core -n ckad-ns-a >/dev/null 2>&1 && {
  echo "✓ Pod web-core exists in ckad-ns-a"
  exit 0
} || {
  echo "✗ Pod web-core not found in ckad-ns-a"
  exit 1
}
