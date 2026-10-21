#!/usr/bin/env bash
set -euo pipefail
kubectl -n secrets-cm get pod secret-handler -o name >/dev/null
