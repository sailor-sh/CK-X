#!/usr/bin/env bash
# Q16.02 - Liveness probe configured correctly
# Points: 4

NS="liveness-probes"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
CMD=$(jp pod live-check "$NS" .spec.containers[0].livenessProbe.exec.command[0])
expect_equals "$CMD" "cat" \
  "Liveness probe exec command configured" \
  "Liveness probe not configured as expected"
