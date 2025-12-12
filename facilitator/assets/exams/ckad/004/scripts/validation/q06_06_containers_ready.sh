#!/bin/bash
# Q06.06 - Both containers ready
# Points: 2

READY=$(kubectl get pod multi-container -n q06 -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)
[[ "$READY" == "true" ]] && {
  echo "✓ Containers ready"
  exit 0
} || {
  echo "✗ Containers not ready"
  exit 1
}
