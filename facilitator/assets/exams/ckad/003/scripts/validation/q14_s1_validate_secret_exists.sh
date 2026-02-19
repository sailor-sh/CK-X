#!/usr/bin/env bash
set -euo pipefail
kubectl -n secrets-cm get secret secret1 -o name >/dev/null
