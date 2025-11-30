#!/usr/bin/env bash
set -euo pipefail
NS=ckad-q08
DEP=api-new-c32
kubectl -n "$NS" get deploy "$DEP" >/dev/null 2>&1 || { echo "deployment missing"; exit 1; }
DESIRED=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.replicas}')
AVAILABLE=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.status.availableReplicas}')
test "$DESIRED" = "$AVAILABLE" || { echo "deployment not fully available"; exit 1; }
