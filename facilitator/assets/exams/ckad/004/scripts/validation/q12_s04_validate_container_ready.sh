#!/bin/bash
# Q12.04 - Container status correct
# Points: 2

READY=$(kubectl get pod logging-pod -n q12 -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)
[[ "$READY" == "true" ]] && {
  echo "✓ Container ready"
  exit 0
} || {
  echo "✗ Container not ready"
  exit 1
}
