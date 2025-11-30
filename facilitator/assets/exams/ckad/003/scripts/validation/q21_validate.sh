#!/usr/bin/env bash
set -euo pipefail
NS=ckad-p2
kubectl -n "$NS" get deploy sunny >/dev/null 2>&1 || { echo "deployment missing"; exit 1; }
R=$(kubectl -n "$NS" get deploy sunny -o jsonpath='{.spec.replicas}')
test "$R" = "4" || { echo "replicas not 4"; exit 1; }
kubectl -n "$NS" get svc sun-srv >/dev/null 2>&1 || { echo "service missing"; exit 1; }
test -x /opt/course/exam3/p2/sunny_status_command.sh || { echo "status script missing or not executable"; exit 1; }
