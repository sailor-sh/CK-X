#!/bin/bash
# Q17.4 - Readiness probe is configured
# Points: 2

kubectl get pod ready-web -n readiness-probes -o jsonpath='{.spec.containers[0].readinessProbe}' 2>/dev/null | grep -q 'httpGet' && {
  echo "✓ Readiness probe is configured"
  exit 0
} || {
  echo "✗ Readiness probe not configured"
  exit 1
}
