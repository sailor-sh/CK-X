#!/usr/bin/env bash
set -euo pipefail
# At least one pod should have label id=awesome-job
kubectl -n jobs get pods -l id=awesome-job --no-headers | grep -q .
