#!/usr/bin/env bash
# Q04.02 - Shared emptyDir volume defined (shared-log)
# Points: 2

NS="sidecar-logging"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
V=$(jp pod logger-pod "$NS" '.spec.volumes[?(@.name=="shared-log")].emptyDir')
expect_nonempty "$V" \
  "emptyDir volume 'shared-log' defined" \
  "emptyDir volume 'shared-log' not found"
