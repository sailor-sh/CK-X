#!/bin/bash
# Q13.04 - Variables accessible in container
# Points: 2

EXEC=$(kubectl exec env-pod -n q13 -- env 2>/dev/null)
[[ -n "$EXEC" ]] && {
  echo "✓ Vars accessible"
  exit 0
} || {
  echo "✗ Not accessible"
  exit 1
}
