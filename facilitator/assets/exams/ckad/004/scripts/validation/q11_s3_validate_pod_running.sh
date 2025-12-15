#!/usr/bin/env bash
# Q11.03 - Pod cm-pod is running
# Points: 2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

NS="configmaps-env"
PHASE=$(pod_phase cm-pod "$NS")
expect_equals "$PHASE" "Running" \
  "Pod cm-pod is Running" \
  "Pod cm-pod phase is '$PHASE', expected 'Running'"
