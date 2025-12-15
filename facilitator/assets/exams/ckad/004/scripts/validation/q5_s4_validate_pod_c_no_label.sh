#!/usr/bin/env bash
# Q05.04 - pod-c does NOT have env=prod label
# Points: 2

NS="labels-selectors"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
VAL=$(jp pod pod-c "$NS" .metadata.labels.env)
if [[ "$VAL" != "prod" ]]; then
  ok "pod-c does not have env=prod"
else
  fail "pod-c incorrectly has env=prod"
fi
