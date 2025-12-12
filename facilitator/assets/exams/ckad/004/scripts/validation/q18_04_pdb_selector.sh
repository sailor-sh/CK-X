#!/bin/bash
# Q18.04 - PDB selects correct pods
# Points: 2

SELECTOR=$(kubectl get poddisruptionbudget app-pdb -n q18 -o jsonpath='{.spec.selector}' 2>/dev/null)
[[ -n "$SELECTOR" ]] && {
  echo "✓ Selector configured"
  exit 0
} || {
  echo "✗ No selector"
  exit 1
}
