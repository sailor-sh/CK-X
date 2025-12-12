#!/bin/bash
# Q22.01 - Web deployment exists
# Points: 2

kubectl get deployment web-tier -n q22 >/dev/null 2>&1 && {
  echo "✓ Deployment web-tier exists"
  exit 0
} || {
  echo "✗ Deployment not found"
  exit 1
}
