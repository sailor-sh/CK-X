#!/usr/bin/env bash
set -euo pipefail
kubectl -n ckad-q15 get configmap configmap-web-moon-html >/dev/null 2>&1

