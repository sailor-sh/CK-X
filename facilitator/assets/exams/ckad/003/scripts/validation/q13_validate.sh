#!/usr/bin/env bash
set -euo pipefail
NS=ckad-q13
SC=moon-retain
PVC=moon-pvc-126
FILE=/opt/course/exam3/q13/pvc-126-reason
kubectl get storageclass "$SC" >/dev/null 2>&1 || { echo "SC missing"; exit 1; }
kubectl -n "$NS" get pvc "$PVC" >/dev/null 2>&1 || { echo "PVC missing"; exit 1; }
PHASE=$(kubectl -n "$NS" get pvc "$PVC" -o jsonpath='{.status.phase}')
test "$PHASE" = "Pending" || { echo "PVC not Pending"; exit 1; }
test -s "$FILE" || { echo "reason file missing or empty"; exit 1; }
