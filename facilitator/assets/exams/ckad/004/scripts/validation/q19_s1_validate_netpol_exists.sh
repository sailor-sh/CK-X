#!/usr/bin/env bash
# Q19.01 - NetworkPolicy default-deny exists
# Points: 3

NS="network-policies"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
if k_exists networkpolicy default-deny "$NS"; then
  ok "NetworkPolicy default-deny exists in $NS"
else
  fail "NetworkPolicy default-deny not found in $NS"
fi
