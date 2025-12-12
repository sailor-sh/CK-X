#!/bin/bash
# Q11.05 - Probe timing appropriate
# Points: 2

DELAY=$(kubectl get deployment no-liveness -n q11 -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.initialDelaySeconds}' 2>/dev/null)
[[ -n "$DELAY" ]] && {
  echo "✓ Timing configured: ${DELAY}s"
  exit 0
} || {
  echo "✗ No timing"
  exit 1
}
