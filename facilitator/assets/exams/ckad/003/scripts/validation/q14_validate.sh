#!/usr/bin/env bash
set -euo pipefail
NS=ckad-q14
kubectl -n "$NS" get secret secret1 >/dev/null 2>&1 || { echo "secret1 missing"; exit 1; }
kubectl -n "$NS" get pod secret-handler >/dev/null 2>&1 || { echo "pod missing"; exit 1; }
test -f /opt/course/exam3/q14/secret-handler-new.yaml || { echo "updated yaml missing"; exit 1; }
