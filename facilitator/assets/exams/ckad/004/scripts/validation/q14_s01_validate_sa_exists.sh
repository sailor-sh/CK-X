#!/bin/bash
# Q14.01 - ServiceAccount exists
# Points: 2

kubectl get serviceaccount app-sa -n q14 >/dev/null 2>&1 && {
  echo "✓ ServiceAccount app-sa exists"
  exit 0
} || {
  echo "✗ ServiceAccount not found"
  exit 1
}
