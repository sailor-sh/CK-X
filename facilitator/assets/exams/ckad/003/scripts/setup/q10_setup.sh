#!/usr/bin/env bash
set -euo pipefail
kubectl get ns services-curl >/dev/null 2>&1 || kubectl create ns services-curl
mkdir -p /opt/course/exam3/q10
