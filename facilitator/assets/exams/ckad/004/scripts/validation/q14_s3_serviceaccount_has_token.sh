#!/bin/bash
# Q14.3 - ServiceAccount has token
# Points: 2

kubectl get serviceaccount backend-sa -n service-accounts -o jsonpath='{.secrets}' 2>/dev/null | grep -q 'backend-sa-token' && {
  echo "✓ ServiceAccount has token"
  exit 0
} || {
  echo "✗ ServiceAccount missing token"
  exit 1
}
