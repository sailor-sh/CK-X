#!/usr/bin/env bash
set -euo pipefail
NS=ckad-q09
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"
kubectl -n "$NS" delete pod holy-api --ignore-not-found=true
kubectl -n "$NS" run holy-api --image=nginx:1.17.3-alpine --restart=Never
echo "Seeded Pod holy-api in ${NS}."
