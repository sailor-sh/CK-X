#!/usr/bin/env bash
set -euo pipefail
kubectl -n ckad-p2 get svc sun-srv >/dev/null 2>&1

