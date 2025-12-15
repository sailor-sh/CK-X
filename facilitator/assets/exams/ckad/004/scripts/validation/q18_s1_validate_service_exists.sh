#!/usr/bin/env bash
# Q18.01 - Service web-svc exists
# Points: 2

NS="services-clusterip"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
if k_exists svc web-svc "$NS"; then
  ok "Service web-svc exists in $NS"
else
  fail "Service web-svc not found in $NS"
fi
