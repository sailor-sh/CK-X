#!/bin/bash
# Q06.02 - Two containers present
# Points: 2

CONTAINERS=$(kubectl get pod multi-container -n q06 -o jsonpath='{.spec.containers | length}' 2>/dev/null)
[[ "$CONTAINERS" == "2" ]] && {
  echo "✓ Two containers present"
  exit 0
} || {
  echo "✗ Found $CONTAINERS containers, expected 2"
  exit 1
}
