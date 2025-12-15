#!/bin/bash
# Q13.5 - Container has security settings
# Points: 2

kubectl get pod secure-pod -n security-contexts -o jsonpath='{.spec.containers[0].securityContext}' 2>/dev/null | grep -q 'runAsNonRoot' && {
  echo "✓ Container has security settings"
  exit 0
} || {
  echo "✗ Container missing security settings"
  exit 1
}
