#!/usr/bin/env bash
# Q17.01 - Pod ready-web exists
# Points: 2

NS="readiness-probes"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
if k_exists pod ready-web "$NS"; then
  ok "Pod ready-web exists in $NS"
else
  fail "Pod ready-web not found in $NS"
fi
