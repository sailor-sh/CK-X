#!/usr/bin/env bash
set -euo pipefail
PHASE=$(kubectl -n ckad-q13 get pvc moon-pvc-126 -o jsonpath='{.status.phase}')
test "$PHASE" = "Pending"

