#!/usr/bin/env bash
# Q11.01 - ConfigMap app-config exists
# Points: 2

NS="configmaps-env"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
if k_exists configmap app-config "$NS"; then
  ok "ConfigMap app-config exists in $NS"
else
  fail "ConfigMap app-config not found in $NS"
fi
