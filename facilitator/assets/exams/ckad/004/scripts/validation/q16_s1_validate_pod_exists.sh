#!/usr/bin/env bash
# Q16.01 - Pod live-check exists
# Points: 2

NS="liveness-probes"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
if k_exists pod live-check "$NS"; then
  ok "Pod live-check exists in $NS"
else
  fail "Pod live-check not found in $NS"
fi
