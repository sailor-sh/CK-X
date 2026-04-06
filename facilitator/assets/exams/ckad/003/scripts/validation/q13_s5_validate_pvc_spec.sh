#!/usr/bin/env bash
set -euo pipefail

ns=pvc-pending
pvc=moon-pvc-126

scn=$(kubectl -n "$ns" get pvc "$pvc" -o jsonpath='{.spec.storageClassName}')
req=$(kubectl -n "$ns" get pvc "$pvc" -o jsonpath='{.spec.resources.requests.storage}')
ams=$(kubectl -n "$ns" get pvc "$pvc" -o jsonpath='{.spec.accessModes[*]}')

test "$scn" = "moon-retain"
test "$req" = "3Gi"
printf "%s" "$ams" | grep -q "ReadWriteOnce"
