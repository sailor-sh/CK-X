#!/usr/bin/env bash
# Q20.01 - PVC data-pvc exists and is Bound
# Points: 3

NS="persistent-storage"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
STATUS=$(jp pvc data-pvc "$NS" .status.phase)
expect_equals "$STATUS" "Bound" \
  "PVC data-pvc exists and is Bound" \
  "PVC data-pvc not Bound (status: $STATUS)"
