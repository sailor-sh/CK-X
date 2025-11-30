#!/usr/bin/env bash
set -euo pipefail
kubectl -n ckad-q12 get deploy project-earthflower >/dev/null 2>&1

