#!/usr/bin/env bash
set -euo pipefail
EPS=$(kubectl -n ckad-q18 get endpoints manager-api-svc -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || true)
test -n "$EPS"

