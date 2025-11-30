#!/usr/bin/env bash
set -euo pipefail
kubectl -n ckad-q18 get svc manager-api-svc >/dev/null 2>&1

