#!/bin/bash
# Q11.03 - Probe type correct
# Points: 2

HTTP=$(kubectl get deployment no-liveness -n q11 -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.httpGet}' 2>/dev/null)
[[ -n "$HTTP" ]] && {
  echo "✓ HTTP probe configured"
  exit 0
} || {
  echo "✗ Wrong probe type"
  exit 1
}
