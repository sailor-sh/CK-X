#!/bin/bash
# Q19.01 - NetworkPolicy default-deny exists
# Points: 3

NS="network-policies"
kubectl get networkpolicy default-deny -n "$NS" >/dev/null 2>&1 && {
  echo "✓ NetworkPolicy default-deny exists in $NS"
  exit 0
} || {
  echo "✗ NetworkPolicy default-deny not found in $NS"
  exit 1
}

