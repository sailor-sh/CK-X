#!/bin/bash
# Q20.01 - Deployment exists
# Points: 2

kubectl get deployment scalable-app -n q20 >/dev/null 2>&1 && {
  echo "✓ Deployment scalable-app exists"
  exit 0
} || {
  echo "✗ Deployment not found"
  exit 1
}
