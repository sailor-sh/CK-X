#!/bin/bash
# Q11.02 - Liveness probe defined
# Points: 2

PROBE=$(kubectl get deployment no-liveness -n q11 -o jsonpath='{.spec.template.spec.containers[0].livenessProbe}' 2>/dev/null)
[[ -n "$PROBE" ]] && {
  echo "✓ Liveness probe defined"
  exit 0
} || {
  echo "✗ No liveness probe"
  exit 1
}
