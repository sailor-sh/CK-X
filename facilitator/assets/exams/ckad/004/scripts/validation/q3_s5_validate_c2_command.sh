#!/bin/bash
# Q03.05 - Container c2 has correct command
# Points: 2

COMMAND=$(kubectl get pod multi-box -n multi-container -o jsonpath='{.spec.containers[1].command}' 2>/dev/null)
[[ -n "$COMMAND" ]] && {
  echo "✓ Container c2 has command"
  exit 0
} || {
  echo "✗ Container c2 has no command"
  exit 1
}
