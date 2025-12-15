#!/usr/bin/env bash
# Q05.02 - pod-a has env=prod label
# Points: 2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

NS="labels-selectors"
VAL=$(jp pod pod-a "$NS" .metadata.labels.env)
expect_equals "$VAL" "prod" \
  "pod-a has label env=prod" \
  "pod-a label env is '$VAL', expected 'prod'"
