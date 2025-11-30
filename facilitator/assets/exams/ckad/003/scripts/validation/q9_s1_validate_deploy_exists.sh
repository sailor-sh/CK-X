#!/usr/bin/env bash
set -euo pipefail
kubectl -n ckad-q09 get deploy holy-api >/dev/null 2>&1

