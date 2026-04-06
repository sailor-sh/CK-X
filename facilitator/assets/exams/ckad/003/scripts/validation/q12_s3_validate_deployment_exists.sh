#!/usr/bin/env bash
set -euo pipefail
kubectl -n storage-hostpath get deploy project-earthflower -o name >/dev/null
