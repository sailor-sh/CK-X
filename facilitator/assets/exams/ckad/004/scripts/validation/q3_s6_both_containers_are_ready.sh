#!/bin/bash
# Q3.6 - Both containers are ready
# Points: 2

kubectl get pod multi-box -n multi-container -o jsonpath='{.status.containerStatuses[*].ready}' 2>/dev/null | grep -q 'true true' && {
  echo "✓ Both containers are ready"
  exit 0
} || {
  echo "✗ Not all containers ready"
  exit 1
}
