#!/usr/bin/env bash
set -euo pipefail
kubectl -n ckad-q17 get deploy test-init-container >/dev/null 2>&1

