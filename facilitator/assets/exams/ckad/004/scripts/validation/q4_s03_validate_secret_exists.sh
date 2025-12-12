#!/bin/bash
# Q04.03 - Secret app-secret exists
# Points: 2

kubectl get secret app-secret -n q04 >/dev/null 2>&1 && {
  echo "✓ Secret app-secret exists"
  exit 0
} || {
  echo "✗ Secret app-secret not found"
  exit 1
}
