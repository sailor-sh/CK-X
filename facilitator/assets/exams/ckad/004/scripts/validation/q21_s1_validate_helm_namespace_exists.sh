#!/bin/bash
# Q21.01 - Namespace helm-ns exists
# Points: 2

kubectl get ns helm-ns >/dev/null 2>&1 && {
  echo "✓ Namespace helm-ns exists"
  exit 0
} || {
  echo "✗ Namespace helm-ns not found"
  exit 1
}

