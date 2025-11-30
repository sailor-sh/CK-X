#!/usr/bin/env bash
set -euo pipefail
NS="ckad-p2"
kubectl get ns "$NS" >/dev/null 2>&1
