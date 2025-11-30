#!/usr/bin/env bash
set -euo pipefail
NS=ckad-q12
PV=earth-project-earthflower-pv
PVC=earth-project-earthflower-pvc
DEP=project-earthflower
kubectl get pv "$PV" >/dev/null 2>&1 || { echo "PV missing"; exit 1; }
kubectl -n "$NS" get pvc "$PVC" >/dev/null 2>&1 || { echo "PVC missing"; exit 1; }
PHASE=$(kubectl -n "$NS" get pvc "$PVC" -o jsonpath='{.status.phase}')
test "$PHASE" = "Bound" || { echo "PVC not Bound"; exit 1; }
kubectl -n "$NS" get deploy "$DEP" >/dev/null 2>&1 || { echo "Deployment missing"; exit 1; }
