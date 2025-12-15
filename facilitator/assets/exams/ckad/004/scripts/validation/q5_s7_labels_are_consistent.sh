#!/bin/bash
# Q5.7 - Labels are consistent
# Points: 2

kubectl get pods -n labels-selectors -o jsonpath='{.items[*].metadata.labels}' 2>/dev/null | grep -q 'env:' && {
  echo "✓ Labels are consistent"
  exit 0
} || {
  echo "✗ Labels inconsistent"
  exit 1
}
