#!/usr/bin/env bash
set -euo pipefail

# Validate StorageClass moon-retain fields without external tools
prov=$(kubectl get sc moon-retain -o jsonpath='{.provisioner}')
reclaim=$(kubectl get sc moon-retain -o jsonpath='{.reclaimPolicy}')
vbm=$(kubectl get sc moon-retain -o jsonpath='{.volumeBindingMode}')

test "$prov" = "moon-retainer"
test "$reclaim" = "Retain"
# Default is Immediate; still assert explicitly per question text
test "$vbm" = "Immediate"
