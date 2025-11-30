#!/usr/bin/env bash
set -euo pipefail
NS=ckad-q08
DEP=api-new-c32
DESIRED=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.replicas}')
AVAILABLE=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.status.availableReplicas}')
test "$DESIRED" = "$AVAILABLE"

