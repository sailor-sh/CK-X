#!/bin/bash
# Q11.01 - Deployment exists
# Points: 2

kubectl get deployment no-liveness -n q11 >/dev/null 2>&1 && {
  echo "✓ Deployment no-liveness exists"
  exit 0
} || {
  echo "✗ Deployment not found"
  exit 1
}
