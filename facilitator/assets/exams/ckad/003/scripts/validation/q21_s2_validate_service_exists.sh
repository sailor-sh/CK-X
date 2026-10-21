#!/usr/bin/env bash
set -euo pipefail
kubectl -n p2-deploy-svc get svc sun-srv -o name >/dev/null
