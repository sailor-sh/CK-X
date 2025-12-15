#!/bin/bash
# Q12.5 - Secret contains required keys
# Points: 2

kubectl get secret app-secret -n secrets-volume -o jsonpath='{.data}' 2>/dev/null | grep -q 'username' && {
  echo "✓ Secret contains required keys"
  exit 0
} || {
  echo "✗ Secret missing keys"
  exit 1
}
