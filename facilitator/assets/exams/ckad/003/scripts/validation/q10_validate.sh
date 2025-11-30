#!/usr/bin/env bash
set -euo pipefail
NS=ckad-q10
SVC=project-plt-6cc-svc
POD=project-plt-6cc-api
OUT=/opt/course/exam3/q10/service_test.html
kubectl -n "$NS" get svc "$SVC" >/dev/null 2>&1 || { echo "service missing"; exit 1; }
PORTS=$(kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.spec.ports[0].port}:{.spec.ports[0].targetPort}')
test "$PORTS" = "3333:80" || { echo "wrong port mapping"; exit 1; }
kubectl -n "$NS" get pod "$POD" >/dev/null 2>&1 || { echo "pod missing"; exit 1; }
test -f "$OUT" || { echo "output file missing"; exit 1; }
