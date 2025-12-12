#!/bin/bash
# Q18.01 - Deployment exists
# Points: 2

kubectl get deployment app-deploy -n q18 >/dev/null 2>&1 && {
  echo "✓ Deployment app-deploy exists"
  exit 0
} || {
  echo "✗ Deployment not found"
  exit 1
}
