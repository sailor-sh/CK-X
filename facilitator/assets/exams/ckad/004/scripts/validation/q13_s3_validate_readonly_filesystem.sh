#!/usr/bin/env bash
# Q13.03 - Read-only root filesystem
# Points: 3

NS="security-contexts"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
RO=$(jp pod secure-pod "$NS" .spec.containers[0].securityContext.readOnlyRootFilesystem)
expect_equals "$RO" "true" \
  "Container has readOnlyRootFilesystem=true" \
  "readOnlyRootFilesystem is '$RO', expected 'true'"
