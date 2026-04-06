#!/usr/bin/env bash
set -euo pipefail
kubectl -n init-container get deploy test-init-container -o name >/dev/null
