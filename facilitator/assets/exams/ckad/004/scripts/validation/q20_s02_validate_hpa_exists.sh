#!/bin/bash
# Q20.02 - HPA exists
# Points: 2

kubectl get hpa app-hpa -n q20 >/dev/null 2>&1 && {
  echo "✓ HPA app-hpa exists"
  exit 0
} || {
  echo "✗ HPA not found"
  exit 1
}
