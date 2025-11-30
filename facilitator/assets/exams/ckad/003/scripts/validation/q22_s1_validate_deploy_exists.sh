#!/usr/bin/env bash
set -euo pipefail
kubectl -n ckad-p3 get deploy earth-3cc-web >/dev/null 2>&1

