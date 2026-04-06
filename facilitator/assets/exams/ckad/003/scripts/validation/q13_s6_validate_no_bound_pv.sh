#!/usr/bin/env bash
set -euo pipefail

ns=pvc-pending
pvc=moon-pvc-126

volname=$(kubectl -n "$ns" get pvc "$pvc" -o jsonpath='{.spec.volumeName}' 2>/dev/null || true)
phase=$(kubectl -n "$ns" get pvc "$pvc" -o jsonpath='{.status.phase}' 2>/dev/null || true)

# Ensure no PV is bound and PVC remains Pending
test -z "$volname"
test "$phase" = "Pending"

