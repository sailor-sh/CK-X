#!/usr/bin/env bash
set -euo pipefail
kubectl get ns service-accounts >/dev/null 2>&1 || kubectl create ns service-accounts
kubectl -n service-accounts get sa neptune-sa-v2 >/dev/null 2>&1 || kubectl -n service-accounts create sa neptune-sa-v2
mkdir -p /opt/course/exam3/q05
