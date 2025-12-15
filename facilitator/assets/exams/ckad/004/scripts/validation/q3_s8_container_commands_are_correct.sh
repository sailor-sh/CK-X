#!/bin/bash
# Q3.8 - Container commands are correct
# Points: 2

kubectl get pod multi-box -n multi-container -o jsonpath='{.spec.containers[*].command}' 2>/dev/null | grep -q 'nginx' && {
  echo "✓ Container commands are correct"
  exit 0
} || {
  echo "✗ Container commands incorrect"
  exit 1
}
