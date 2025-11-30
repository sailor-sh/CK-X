#!/usr/bin/env bash
set -euo pipefail
NS=ckad-q10
SVC=project-plt-6cc-svc
PORT=$(kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.spec.ports[0].port}')
TPORT=$(kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.spec.ports[0].targetPort}')
test "$PORT:$TPORT" = "3333:80"

