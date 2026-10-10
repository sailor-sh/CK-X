#!/usr/bin/env bash
set -euo pipefail
kubectl -n p1-liveness get deploy project-23-api -o name >/dev/null
