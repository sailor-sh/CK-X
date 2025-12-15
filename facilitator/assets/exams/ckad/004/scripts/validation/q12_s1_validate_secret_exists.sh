#!/usr/bin/env bash
# Q12.01 - Secret app-secret exists
# Points: 2

NS="secrets-volume"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
if k_exists secret app-secret "$NS"; then
  ok "Secret app-secret exists in $NS"
else
  fail "Secret app-secret not found in $NS"
fi
