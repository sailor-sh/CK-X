#!/usr/bin/env bash
# Q22.01 - CRD definition is correct
# Points: 4

# Check if CRD exists with correct specification
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
GROUP=$(jp crd backups.stable.example.com default .spec.group)
expect_equals "$GROUP" "stable.example.com" \
  "CRD backups.stable.example.com has correct group" \
  "CRD definition incorrect or missing"
