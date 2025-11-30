#!/usr/bin/env bash
set -euo pipefail
NS=ckad-q08
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

# Create a working deployment then roll to a bad image to seed a failed revision
kubectl -n "$NS" delete deploy api-new-c32 --ignore-not-found=true
kubectl -n "$NS" create deploy api-new-c32 --image=nginx:1.17.3-alpine
kubectl -n "$NS" rollout status deploy/api-new-c32 --timeout=60s || true
# Set a broken image to require rollback
kubectl -n "$NS" set image deploy/api-new-c32 nginx=nginx:doesnotexist || true
echo "Seeded api-new-c32 with a bad rollout in ${NS}."
