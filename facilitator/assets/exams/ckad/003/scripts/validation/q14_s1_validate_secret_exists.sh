#!/usr/bin/env bash
set -euo pipefail
kubectl -n ckad-q14 get secret secret1 >/dev/null 2>&1

