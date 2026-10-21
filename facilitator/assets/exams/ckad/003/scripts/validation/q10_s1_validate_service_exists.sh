#!/usr/bin/env bash
set -euo pipefail
kubectl -n services-curl get svc project-plt-6cc-svc -o name >/dev/null
