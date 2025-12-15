#!/bin/bash
# Q16.4 - Liveness probe is configured
# Points: 2

kubectl get pod live-check -n liveness-probes -o jsonpath='{.spec.containers[0].livenessProbe}' 2>/dev/null | grep -q 'httpGet' && {
  echo "✓ Liveness probe is configured"
  exit 0
} || {
  echo "✗ Liveness probe not configured"
  exit 1
}
