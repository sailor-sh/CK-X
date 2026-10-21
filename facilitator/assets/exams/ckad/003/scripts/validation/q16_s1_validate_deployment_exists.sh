#!/usr/bin/env bash
set -euo pipefail
kubectl -n sidecar-logging get deploy cleaner -o name >/dev/null
