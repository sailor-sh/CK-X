#!/usr/bin/env bash
set -euo pipefail
NS=ckad-q09
DEP=holy-api
FILE=/opt/course/exam3/q09/holy-api-deployment.yaml
kubectl -n "$NS" get deploy "$DEP" >/dev/null 2>&1 || { echo "deployment missing"; exit 1; }
R=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.replicas}')
test "$R" = "3" || { echo "replicas not 3"; exit 1; }
test -f "$FILE" || { echo "yaml file missing"; exit 1; }
