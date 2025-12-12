#!/bin/bash
# Q18.03 - PDB minAvailable set
# Points: 2

MINAVAIL=$(kubectl get poddisruptionbudget app-pdb -n q18 -o jsonpath='{.spec.minAvailable}' 2>/dev/null)
[[ -n "$MINAVAIL" ]] && {
  echo "✓ minAvailable: $MINAVAIL"
  exit 0
} || {
  echo "✗ minAvailable not set"
  exit 1
}
