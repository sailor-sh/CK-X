#!/usr/bin/env bash
# Q22.02 - Custom Resource instance exists
# Points: 4

# Check if custom resource instance exists
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
if k_exists backup my-backup crds; then
  ok "Custom Resource instance my-backup exists"
else
  fail "Custom Resource instance my-backup not found"
fi
