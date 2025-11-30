#!/usr/bin/env bash
set -euo pipefail
R=$(kubectl -n ckad-p2 get deploy sunny -o jsonpath='{.spec.replicas}' 2>/dev/null || true)
test "$R" = "4"

