#!/usr/bin/env bash
set -euo pipefail
NS=ckad-q06
POD=pod6
kubectl -n "$NS" get pod "$POD" >/dev/null 2>&1 || { echo "pod missing"; exit 1; }
COND=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
test "$COND" = "True" || { echo "pod not Ready"; exit 1; }
