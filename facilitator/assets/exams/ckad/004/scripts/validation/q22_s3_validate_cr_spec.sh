#!/usr/bin/env bash
# Q22.03 - CR spec matches requirements
# Points: 2

# Check if the CR has the expected structure
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
SPEC=$(kubectl get backup my-backup -n crds -o jsonpath='{.spec}' 2>/dev/null)
expect_contains "$SPEC" "backup" \
  "Custom Resource spec is valid" \
  "Custom Resource spec does not match requirements"
