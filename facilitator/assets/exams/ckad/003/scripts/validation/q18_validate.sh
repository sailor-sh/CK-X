#!/usr/bin/env bash
set -euo pipefail
NS=ckad-q18
SVC=manager-api-svc
kubectl -n "$NS" get svc "$SVC" >/dev/null 2>&1 || { echo "service missing"; exit 1; }
EPS=$(kubectl -n "$NS" get endpoints "$SVC" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || true)
test -n "$EPS" || { echo "service has no endpoints"; exit 1; }
