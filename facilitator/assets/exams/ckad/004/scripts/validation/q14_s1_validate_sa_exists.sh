#!/usr/bin/env bash
# Q14.01 - ServiceAccount exists
# Points: 2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
if k_exists serviceaccount app-sa service-accounts; then
  ok "ServiceAccount app-sa exists in service-accounts"
else
  fail "ServiceAccount app-sa not found in service-accounts"
fi
