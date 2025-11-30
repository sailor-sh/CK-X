#!/usr/bin/env bash
set -euo pipefail
kubectl -n ckad-q10 get pod project-plt-6cc-api >/dev/null 2>&1

