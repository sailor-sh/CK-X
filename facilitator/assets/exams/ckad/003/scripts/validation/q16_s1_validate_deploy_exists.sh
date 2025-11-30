#!/usr/bin/env bash
set -euo pipefail
kubectl -n ckad-q16 get deploy cleaner >/dev/null 2>&1

