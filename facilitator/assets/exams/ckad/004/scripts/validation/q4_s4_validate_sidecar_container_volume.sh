#!/usr/bin/env bash
# Q04.04 - Sidecar container mounts volume at /var/log
# Points: 2

NS="sidecar-logging"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
MP=$(jp pod logger-pod "$NS" '.spec.containers[?(@.name=="sidecar")].volumeMounts[?(@.name=="shared-log")].mountPath')
expect_equals "$MP" "/var/log" \
  "Sidecar container mounts shared-log at /var/log" \
  "Sidecar container mountPath is '$MP', expected '/var/log'"
