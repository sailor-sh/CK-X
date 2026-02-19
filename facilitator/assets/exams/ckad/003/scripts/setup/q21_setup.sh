#!/usr/bin/env bash
set -euo pipefail
kubectl get ns p2-deploy-svc >/dev/null 2>&1 || kubectl create ns p2-deploy-svc
kubectl -n p2-deploy-svc get sa sa-sun-deploy >/dev/null 2>&1 || kubectl -n p2-deploy-svc create sa sa-sun-deploy
mkdir -p /opt/course/exam3/p2
