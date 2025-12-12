#!/bin/bash
# Q15.02 - Backend deployment exists
# Points: 2

kubectl get deployment backend -n q15 >/dev/null 2>&1 && {
  echo "✓ Backend deployment exists"
  exit 0
} || {
  echo "✗ Backend deployment not found"
  exit 1
}
