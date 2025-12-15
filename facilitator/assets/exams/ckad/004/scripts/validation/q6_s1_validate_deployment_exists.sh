#!/usr/bin/env bash
# Q06.01 - Deployment web-deploy exists
# Points: 2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

NS="deployments-scaling"
if k_exists deploy web-deploy "$NS"; then
  ok "Deployment web-deploy exists in $NS"
else
  fail "Deployment web-deploy not found in $NS"
fi
