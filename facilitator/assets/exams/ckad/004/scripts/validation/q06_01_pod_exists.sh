#!/bin/bash
# Q06.01 - Pod multi-container exists
# Points: 2

kubectl get pod multi-container -n q06 >/dev/null 2>&1 && {
  echo "✓ Pod multi-container exists"
  exit 0
} || {
  echo "✗ Pod multi-container not found"
  exit 1
}
