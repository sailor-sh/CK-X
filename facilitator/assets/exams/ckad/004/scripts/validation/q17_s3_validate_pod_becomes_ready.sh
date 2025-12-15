#!/usr/bin/env bash
# Q17.03 - Pod becomes Ready
# Points: 2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

NS="readiness-probes"
READY=$(pod_ready_condition ready-web "$NS")
expect_contains "$READY" "True" \
  "Pod ready-web is Ready" \
  "Pod ready-web is not Ready"
