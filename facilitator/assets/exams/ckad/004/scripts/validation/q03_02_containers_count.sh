#!/bin/bash
# Q03.02 - Pod has 2 containers
# Points: 2

CONTAINERS=$(kubectl get pod multi-box -n q03 -o jsonpath='{.spec.containers | length}' 2>/dev/null)
[[ "$CONTAINERS" == "2" ]] && {
  echo "✓ Pod has 2 containers"
  exit 0
} || {
  echo "✗ Pod has $CONTAINERS containers, expected 2"
  exit 1
}
