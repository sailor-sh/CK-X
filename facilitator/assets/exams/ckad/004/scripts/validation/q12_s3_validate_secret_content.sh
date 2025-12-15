#!/usr/bin/env bash
# Q12.03 - File contains decoded secret
# Points: 3

NS="secrets-volume"
POD="sec-pod"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
OUT=$(kubectl exec -n "$NS" "$POD" -- sh -c 'cat /etc/app-secret/api-key 2>/dev/null' 2>/dev/null)
expect_equals "$OUT" "123456" \
  "Secret file contains expected value" \
  "Secret file content unexpected or not found"
