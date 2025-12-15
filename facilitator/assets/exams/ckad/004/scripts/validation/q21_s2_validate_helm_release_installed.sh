#!/usr/bin/env bash
# Q21.02 - Helm release my-web installed
# Points: 4

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
if helm list -n helm-ns | grep -q "my-web"; then
  ok "Helm release my-web installed"
else
  fail "Helm release my-web not found"
fi
