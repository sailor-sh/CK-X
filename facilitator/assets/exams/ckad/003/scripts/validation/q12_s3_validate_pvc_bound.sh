#!/usr/bin/env bash
set -euo pipefail
PHASE=$(kubectl -n ckad-q12 get pvc earth-project-earthflower-pvc -o jsonpath='{.status.phase}')
test "$PHASE" = "Bound"

