#!/bin/bash
# Q12.4 - Secret has correct type
# Points: 2

kubectl get secret app-secret -n secrets-volume -o jsonpath='{.type}' 2>/dev/null | grep -q 'Opaque' && {
  echo "✓ Secret has correct type"
  exit 0
} || {
  echo "✗ Secret type incorrect"
  exit 1
}
