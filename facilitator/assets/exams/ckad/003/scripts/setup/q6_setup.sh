#!/usr/bin/env bash
set -euo pipefail
kubectl get ns readiness >/dev/null 2>&1 || kubectl create ns readiness
mkdir -p /opt/course/exam3/q06
