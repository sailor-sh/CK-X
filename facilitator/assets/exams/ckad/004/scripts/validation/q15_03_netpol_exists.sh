#!/bin/bash
# Q15.03 - NetworkPolicy created
# Points: 2

NP=$(kubectl get networkpolicy -n q15 --no-headers 2>/dev/null | wc -l)
[[ $NP -gt 0 ]] && {
  echo "✓ NetworkPolicy created"
  exit 0
} || {
  echo "✗ No NetworkPolicy found"
  exit 1
}
