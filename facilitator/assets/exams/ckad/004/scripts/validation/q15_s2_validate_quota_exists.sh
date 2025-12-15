#!/usr/bin/env bash
# Q15.02 - ResourceQuota ns-quota exists in quota-ns
# Points: 2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
if k_exists resourcequota ns-quota quota-ns; then
  ok "ResourceQuota ns-quota exists in quota-ns"
else
  fail "ResourceQuota ns-quota not found in quota-ns"
fi
