#!/usr/bin/env bash
# Q15.03 - ResourceQuota limits pods to 5
# Points: 4

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
VAL=$(jp resourcequota ns-quota quota-ns .spec.hard.pods)
expect_equals "${VAL//$'\n'/}" "5" \
  "ResourceQuota limits pods to 5" \
  "ResourceQuota pods hard limit is '$VAL', expected '5'"
