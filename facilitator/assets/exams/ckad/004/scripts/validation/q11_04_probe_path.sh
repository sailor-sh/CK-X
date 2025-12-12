#!/bin/bash
# Q11.04 - Probe path correct
# Points: 2

PATH=$(kubectl get deployment no-liveness -n q11 -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.httpGet.path}' 2>/dev/null)
[[ -n "$PATH" ]] && {
  echo "✓ Probe path set"
  exit 0
} || {
  echo "✗ No probe path"
  exit 1
}
