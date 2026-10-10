#!/usr/bin/env bash
set -euo pipefail
kubectl -n single-pod get pod pod1 -o name >/dev/null
