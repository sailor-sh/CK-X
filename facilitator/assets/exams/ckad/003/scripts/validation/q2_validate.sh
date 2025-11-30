#!/usr/bin/env bash
set -euo pipefail
NS=ckad-q02
POD=pod1
SCRIPT=/opt/course/exam3/q02/pod1-status-command.sh
kubectl -n "$NS" get pod "$POD" >/dev/null 2>&1 || { echo "pod missing"; exit 1; }
NAME=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.containers[0].name}')
test "$NAME" = "pod1-container" || { echo "container name mismatch"; exit 1; }
test -x "$SCRIPT" || { echo "status script missing or not executable"; exit 1; }
