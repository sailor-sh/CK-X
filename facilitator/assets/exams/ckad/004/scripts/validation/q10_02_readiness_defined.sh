#!/bin/bash
# Q10.02 - Readiness probe defined
# Points: 2

PROBE=$(kubectl get deployment no-readiness -n q10 -o jsonpath='{.spec.template.spec.containers[0].readinessProbe}' 2>/dev/null)
[[ -n "$PROBE" ]] && {
  echo "✓ Readiness probe defined"
  exit 0
} || {
  echo "✗ No readiness probe"
  exit 1
}
