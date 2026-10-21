#!/usr/bin/env bash
set -euo pipefail
kubectl -n services-curl get pod project-plt-6cc-api -o name >/dev/null
