#!/usr/bin/env bash
# Q15.01 - Namespace quota-ns exists
# Points: 2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
if k_exists namespace quota-ns; then
  ok "Namespace quota-ns exists"
else
  fail "Namespace quota-ns not found"
fi
