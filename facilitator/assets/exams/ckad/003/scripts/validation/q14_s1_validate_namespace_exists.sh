#!/usr/bin/env bash
set -euo pipefail
NS="ckad-q14"
kubectl get ns "$NS" >/dev/null 2>&1
