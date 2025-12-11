#!/bin/bash
# Q04.04 - Secret has username
# Points: 2

USERNAME=$(kubectl get secret app-secret -n q04 -o jsonpath='{.data.username}' 2>/dev/null)
[[ -n "$USERNAME" ]] && {
  echo "✓ Secret has username"
  exit 0
} || {
  echo "✗ username key not found"
  exit 1
}
