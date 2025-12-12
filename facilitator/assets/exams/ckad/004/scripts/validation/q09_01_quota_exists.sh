#!/bin/bash
# Q09.01 - ResourceQuota exists
# Points: 2

kubectl get resourcequota -n q09 >/dev/null 2>&1 && {
  echo "✓ ResourceQuota exists"
  exit 0
} || {
  echo "✗ ResourceQuota not found"
  exit 1
}
