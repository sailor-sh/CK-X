#!/bin/bash
# Q6.5 - Deployment has rolling update strategy
# Points: 2

kubectl get deployment web-deploy -n deployments-scaling -o jsonpath='{.spec.strategy.type}' 2>/dev/null | grep -q 'RollingUpdate' && {
  echo "✓ Deployment has rolling update strategy"
  exit 0
} || {
  echo "✗ Deployment strategy incorrect"
  exit 1
}
