#!/usr/bin/env bash
set -euo pipefail
kubectl -n ckad-q05 get sa neptune-sa-v2 >/dev/null 2>&1

