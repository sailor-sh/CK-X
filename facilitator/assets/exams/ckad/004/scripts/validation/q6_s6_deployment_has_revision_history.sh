#!/bin/bash
# Q6.6 - Deployment has revision history
# Points: 2

kubectl rollout history deployment web-deploy -n deployments-scaling 2>/dev/null | grep -q 'REVISION' && {
  echo "✓ Deployment has revision history"
  exit 0
} || {
  echo "✗ No revision history found"
  exit 1
}
