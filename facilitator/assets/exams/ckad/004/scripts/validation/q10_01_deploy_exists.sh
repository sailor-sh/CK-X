#!/bin/bash
# Q10.01 - Deployment exists
# Points: 2

kubectl get deployment no-readiness -n q10 >/dev/null 2>&1 && {
  echo "✓ Deployment no-readiness exists"
  exit 0
} || {
  echo "✗ Deployment not found"
  exit 1
}
