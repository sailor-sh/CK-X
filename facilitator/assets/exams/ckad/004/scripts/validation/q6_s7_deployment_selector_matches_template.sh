#!/bin/bash
# Q6.7 - Deployment selector matches template
# Points: 2

kubectl get deployment web-deploy -n deployments-scaling -o jsonpath='{.spec.selector.matchLabels}' 2>/dev/null | grep -q 'app: web' && {
  echo "✓ Deployment selector matches template"
  exit 0
} || {
  echo "✗ Deployment selector mismatch"
  exit 1
}
