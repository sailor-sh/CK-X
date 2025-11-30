#!/usr/bin/env bash
set -euo pipefail
NS="ckad-q18"
kubectl get ns "$NS" >/dev/null 2>&1
