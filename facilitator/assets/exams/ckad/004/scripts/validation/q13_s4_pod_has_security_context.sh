#!/bin/bash
# Q13.4 - Pod has security context
# Points: 2

kubectl get pod secure-pod -n security-contexts -o jsonpath='{.spec.securityContext}' 2>/dev/null | grep -q 'runAsUser' && {
  echo "✓ Pod has security context"
  exit 0
} || {
  echo "✗ Pod missing security context"
  exit 1
}
