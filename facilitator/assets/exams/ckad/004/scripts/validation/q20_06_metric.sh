#!/bin/bash
# Q20.06 - CPU metric configured
# Points: 2

METRIC=$(kubectl get hpa app-hpa -n q20 -o jsonpath='{.spec.metrics[0].type}' 2>/dev/null)
[[ "$METRIC" == "Resource" ]] && {
  echo "✓ Metric configured"
  exit 0
} || {
  echo "✗ Metric: $METRIC, expected Resource"
  exit 1
}
