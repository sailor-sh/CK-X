#!/usr/bin/env bash
set -euo pipefail
kubectl -n ckad-q03 get job neb-new-job >/dev/null 2>&1

