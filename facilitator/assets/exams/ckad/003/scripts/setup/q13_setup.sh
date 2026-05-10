#!/usr/bin/env bash
set -euo pipefail
kubectl get ns pvc-pending >/dev/null 2>&1 || kubectl create ns pvc-pending
mkdir -p /opt/course/exam3/q13
