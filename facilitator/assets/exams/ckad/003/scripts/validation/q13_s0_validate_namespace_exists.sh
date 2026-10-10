#!/usr/bin/env bash
set -euo pipefail

kubectl get ns pvc-pending -o name >/dev/null

