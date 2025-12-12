#!/bin/bash
# Q15.01 - Frontend deployment exists
# Points: 2

kubectl get deployment frontend -n resource-quotas >/dev/null 2>&1 && {
  echo "✓ Frontend deployment exists"
  exit 0
} || {
  echo "✗ Frontend deployment not found"
  exit 1
}
