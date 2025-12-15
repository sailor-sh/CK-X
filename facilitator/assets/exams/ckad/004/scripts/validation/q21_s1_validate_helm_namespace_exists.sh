#!/usr/bin/env bash
# Q21.01 - Namespace helm-ns exists
# Points: 2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
if k_exists namespace helm-ns; then
  ok "Namespace helm-ns exists"
else
  fail "Namespace helm-ns not found"
fi
