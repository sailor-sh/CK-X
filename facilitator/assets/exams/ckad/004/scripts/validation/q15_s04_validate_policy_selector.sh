#!/bin/bash
# Q15.04 - Policy selects correct pods
# Points: 2

SELECTOR=$(kubectl get networkpolicy -n q15 -o jsonpath='{.items[0].spec.podSelector}' 2>/dev/null)
[[ -n "$SELECTOR" ]] && {
  echo "✓ Pod selector configured"
  exit 0
} || {
  echo "✗ No pod selector"
  exit 1
}
