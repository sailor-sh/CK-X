#!/usr/bin/env bash
set -euo pipefail
kubectl -n jobs get job neb-new-job -o name >/dev/null
