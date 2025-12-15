#!/bin/bash
# Q15.02 - ResourceQuota ns-quota exists in quota-ns
# Points: 2

kubectl get resourcequota ns-quota -n quota-ns >/dev/null 2>&1 && {
  echo "✓ ResourceQuota ns-quota exists in quota-ns"
  exit 0
} || {
  echo "✗ ResourceQuota ns-quota not found in quota-ns"
  exit 1
}

