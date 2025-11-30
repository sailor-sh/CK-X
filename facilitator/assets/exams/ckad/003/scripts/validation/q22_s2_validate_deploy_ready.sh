#!/usr/bin/env bash
set -euo pipefail
NS=ckad-p3
DEP=earth-3cc-web
DESIRED=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.replicas}')
AVAILABLE=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.status.availableReplicas}')
test "$DESIRED" = "$AVAILABLE"

