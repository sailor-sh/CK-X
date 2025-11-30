#!/usr/bin/env bash
set -euo pipefail
NS=ckad-p2
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"
kubectl -n "$NS" delete sa sa-sun-deploy --ignore-not-found=true
kubectl -n "$NS" create sa sa-sun-deploy
mkdir -p /opt/course/exam3/p2
echo "Seeded ServiceAccount sa-sun-deploy and created output dir for ${NS}."
