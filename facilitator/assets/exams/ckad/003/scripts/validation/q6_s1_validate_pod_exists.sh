#!/usr/bin/env bash
set -euo pipefail
kubectl -n ckad-q06 get pod pod6 >/dev/null 2>&1

