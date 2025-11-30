#!/usr/bin/env bash
set -euo pipefail
NS=ckad-p1
kubectl -n "$NS" get deploy project-23-api >/dev/null 2>&1 || { echo "deployment missing"; exit 1; }
test -f /opt/course/exam3/p1/project-23-api-new.yaml || { echo "updated yaml missing"; exit 1; }
