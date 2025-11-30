#!/usr/bin/env bash
set -euo pipefail
NS=ckad-q19
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"
kubectl -n "$NS" delete deploy jupiter-crew-deploy --ignore-not-found=true
kubectl -n "$NS" delete svc jupiter-crew-svc --ignore-not-found=true
kubectl -n "$NS" create deploy jupiter-crew-deploy --image=httpd:2.4.41-alpine
kubectl -n "$NS" expose deploy jupiter-crew-deploy --name jupiter-crew-svc --port 80 --target-port 80 --type ClusterIP
echo "Seeded deployment and ClusterIP service in ${NS}."
