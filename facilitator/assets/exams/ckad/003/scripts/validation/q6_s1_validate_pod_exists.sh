#!/usr/bin/env bash
set -euo pipefail
kubectl -n readiness get pod pod6 -o name >/dev/null
