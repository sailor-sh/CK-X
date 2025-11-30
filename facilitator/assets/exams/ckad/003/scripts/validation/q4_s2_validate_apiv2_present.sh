#!/usr/bin/env bash
set -euo pipefail
kubectl -n ckad-q04 get deploy internal-issue-report-apiv2 >/dev/null 2>&1

