#!/usr/bin/env bash
set -euo pipefail
kubectl -n ckad-p2 get deploy sunny >/dev/null 2>&1

