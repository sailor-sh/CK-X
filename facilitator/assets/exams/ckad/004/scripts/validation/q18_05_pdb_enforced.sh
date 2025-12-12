#!/bin/bash
# Q18.05 - PDB enforced
# Points: 2

ALLOWED=$(kubectl get poddisruptionbudget app-pdb -n q18 -o jsonpath='{.status.disruptionsAllowed}' 2>/dev/null)
[[ -n "$ALLOWED" ]] && {
  echo "✓ PDB enforced"
  exit 0
} || {
  echo "✗ Not enforced"
  exit 1
}
