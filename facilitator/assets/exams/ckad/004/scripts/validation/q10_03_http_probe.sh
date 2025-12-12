#!/bin/bash
# Q10.03 - Probe uses HTTP
# Points: 2

HTTP=$(kubectl get deployment no-readiness -n q10 -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet}' 2>/dev/null)
[[ -n "$HTTP" ]] && {
  echo "✓ HTTP probe configured"
  exit 0
} || {
  echo "✗ Not HTTP probe"
  exit 1
}
