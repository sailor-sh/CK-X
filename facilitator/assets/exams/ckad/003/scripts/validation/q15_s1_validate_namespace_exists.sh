#!/usr/bin/env bash
set -euo pipefail
NS="ckad-q15"
kubectl get ns "$NS" >/dev/null 2>&1
