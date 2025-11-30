#!/usr/bin/env bash
set -euo pipefail
NS=ckad-q19
SVC=jupiter-crew-svc
kubectl -n "$NS" get svc "$SVC" >/dev/null 2>&1 || { echo "service missing"; exit 1; }
TYPE=$(kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.spec.type}')
test "$TYPE" = "NodePort" || { echo "service not NodePort"; exit 1; }
NP=$(kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.spec.ports[0].nodePort}')
test "$NP" = "30100" || { echo "nodePort not 30100"; exit 1; }
