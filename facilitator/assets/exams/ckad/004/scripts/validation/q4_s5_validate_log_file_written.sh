#!/usr/bin/env bash
# Q04.05 - App writes to log file, visible via sidecar
# Points: 2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

NS="sidecar-logging"
LOGS=$(kubectl logs logger-pod -n "$NS" -c sidecar 2>/dev/null | tail -n 20)
expect_contains "$LOGS" "logging info" \
  "Sidecar outputs 'logging info' from shared log" \
  "Expected 'logging info' not found in sidecar logs"
