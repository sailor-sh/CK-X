#!/usr/bin/env bash
# Q14.02 - Pod uses correct ServiceAccount
# Points: 4

NS="service-accounts"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
SA=$(jp pod backend-pod "$NS" .spec.serviceAccountName)
expect_equals "$SA" "backend-sa" \
  "Pod backend-pod uses ServiceAccount backend-sa" \
  "Pod serviceAccountName is '$SA', expected 'backend-sa'"
