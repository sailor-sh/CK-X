#!/usr/bin/env bash
set -euo pipefail
R=$(kubectl -n ckad-q04 get deploy internal-issue-report-apache -o jsonpath='{.spec.replicas}' 2>/dev/null || true)
test "$R" = "2"

