#!/usr/bin/env bash
set -euo pipefail
NS=ckad-q16
kubectl -n "$NS" get deploy cleaner >/dev/null 2>&1 || { echo "deployment missing"; exit 1; }
test -f /opt/course/exam3/q16/cleaner-new.yaml || { echo "updated yaml missing"; exit 1; }
