#!/usr/bin/env bash
set -euo pipefail
NS="ckad-p1"
kubectl get ns "$NS" >/dev/null 2>&1
