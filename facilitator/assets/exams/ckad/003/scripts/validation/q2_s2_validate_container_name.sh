#!/usr/bin/env bash
set -euo pipefail
NAME=$(kubectl -n ckad-q02 get pod pod1 -o jsonpath='{.spec.containers[0].name}' 2>/dev/null || true)
test "$NAME" = "pod1-container"

