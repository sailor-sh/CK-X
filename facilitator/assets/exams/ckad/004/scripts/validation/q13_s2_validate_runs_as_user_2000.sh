#!/usr/bin/env bash
# Q13.02 - Runs as user 2000
# Points: 3

NS="security-contexts"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
USER=$(jp pod secure-pod "$NS" .spec.securityContext.runAsUser)
if [[ -z "$USER" ]]; then
  USER=$(jp pod secure-pod "$NS" .spec.containers[0].securityContext.runAsUser)
fi
expect_equals "$USER" "2000" \
  "Pod/container runs as user 2000" \
  "runAsUser is '$USER', expected '2000'"
