#!/usr/bin/env bash
set -euo pipefail
kubectl -n ckad-q13 get pvc moon-pvc-126 >/dev/null 2>&1

