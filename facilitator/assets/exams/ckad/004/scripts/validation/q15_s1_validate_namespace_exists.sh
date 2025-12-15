#!/bin/bash
# Q15.01 - Namespace quota-ns exists
# Points: 2

kubectl get ns quota-ns >/dev/null 2>&1 && {
  echo "✓ Namespace quota-ns exists"
  exit 0
} || {
  echo "✗ Namespace quota-ns not found"
  exit 1
}

