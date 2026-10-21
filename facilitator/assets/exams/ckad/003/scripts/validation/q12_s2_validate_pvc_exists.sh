#!/usr/bin/env bash
set -euo pipefail
kubectl -n storage-hostpath get pvc earth-project-earthflower-pvc -o name >/dev/null
