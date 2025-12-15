#!/usr/bin/env bash
# Q07.01 - Strategy is RollingUpdate
# Points: 2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

NS="rolling-updates"
STRAT=$(jp deploy web-deploy "$NS" .spec.strategy.type)
expect_equals "$STRAT" "RollingUpdate" \
  "Update strategy is RollingUpdate" \
  "Strategy is '$STRAT', expected 'RollingUpdate'"
