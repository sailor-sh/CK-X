#!/usr/bin/env bash
set -euo pipefail
kubectl get pv earth-project-earthflower-pv -o name >/dev/null

