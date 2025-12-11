#!/bin/bash
# Q01.01 - Namespace ckad-ns-a exists
# Points: 2

kubectl get namespace ckad-ns-a >/dev/null 2>&1 && {
  echo "✓ Namespace ckad-ns-a exists"
  exit 0
} || {
  echo "✗ Namespace ckad-ns-a not found"
  exit 1
}
