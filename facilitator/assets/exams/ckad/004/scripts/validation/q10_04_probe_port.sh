#!/bin/bash
# Q10.04 - Probe checks port 80
# Points: 2

PORT=$(kubectl get deployment no-readiness -n q10 -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.port}' 2>/dev/null)
[[ "$PORT" == "80" ]] && {
  echo "✓ Probe port 80"
  exit 0
} || {
  echo "✗ Probe port is $PORT, expected 80"
  exit 1
}
