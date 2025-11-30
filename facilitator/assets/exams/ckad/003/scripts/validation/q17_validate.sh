#!/usr/bin/env bash
set -euo pipefail
NS=ckad-q17
kubectl -n "$NS" get deploy test-init-container >/dev/null 2>&1 || { echo "deployment missing"; exit 1; }
test -f /opt/course/exam3/q17/test-init-container-new.yaml || { echo "updated yaml missing"; exit 1; }
