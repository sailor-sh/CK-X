#!/usr/bin/env bash
set -euo pipefail
NS=ckad-q15
kubectl -n "$NS" get configmap configmap-web-moon-html >/dev/null 2>&1 || { echo "configmap missing"; exit 1; }
test -f /opt/course/exam3/q15/configmap.yaml || { echo "configmap yaml missing"; exit 1; }
