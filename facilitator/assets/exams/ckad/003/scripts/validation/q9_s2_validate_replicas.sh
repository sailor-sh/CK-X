#!/usr/bin/env bash
set -euo pipefail
R=$(kubectl -n ckad-q09 get deploy holy-api -o jsonpath='{.spec.replicas}' 2>/dev/null || true)
test "$R" = "3"

