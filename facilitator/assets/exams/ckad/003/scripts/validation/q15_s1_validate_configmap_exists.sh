#!/usr/bin/env bash
set -euo pipefail
kubectl -n configmap-web get configmap configmap-web-moon-html -o name >/dev/null
