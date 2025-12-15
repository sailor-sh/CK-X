#!/usr/bin/env bash
# Q05.03 - pod-b has env=prod label
# Points: 2

NS="labels-selectors"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
VAL=$(jp pod pod-b "$NS" .metadata.labels.env)
expect_equals "$VAL" "prod" \
  "pod-b has label env=prod" \
  "pod-b label env is '$VAL', expected 'prod'"
