#!/usr/bin/env bash
set -euo pipefail
eps=$(kubectl -n svc-fix-endpoints get endpoints manager-api-svc -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || true)
test -n "${eps}"
