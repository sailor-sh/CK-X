#!/bin/bash
# Q3.7 - Containers have minimal restarts
# Points: 2

kubectl get pod multi-box -n multi-container -o jsonpath='{.status.containerStatuses[*].restartCount}' 2>/dev/null | grep -q ' 0 0' && {
  echo "✓ Containers have minimal restarts"
  exit 0
} || {
  echo "✗ Containers have excessive restarts"
  exit 1
}
