#!/usr/bin/env bash
set -euo pipefail
NS="ckad-q05"
kubectl get ns "$NS" >/dev/null 2>&1
