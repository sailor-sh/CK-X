#!/bin/bash
# Q04.05 - Secret has password
# Points: 2

PASSWORD=$(kubectl get secret app-secret -n q04 -o jsonpath='{.data.password}' 2>/dev/null)
[[ -n "$PASSWORD" ]] && {
  echo "✓ Secret has password"
  exit 0
} || {
  echo "✗ password key not found"
  exit 1
}
