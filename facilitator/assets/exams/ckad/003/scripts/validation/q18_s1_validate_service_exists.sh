#!/usr/bin/env bash
set -euo pipefail
kubectl -n svc-fix-endpoints get svc manager-api-svc -o name >/dev/null
