#!/bin/bash
# Q18.02 - PDB exists
# Points: 2

kubectl get poddisruptionbudget app-pdb -n q18 >/dev/null 2>&1 && {
  echo "✓ PDB app-pdb exists"
  exit 0
} || {
  echo "✗ PDB not found"
  exit 1
}
