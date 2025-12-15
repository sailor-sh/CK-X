#!/usr/bin/env bash
# Q04.03 - App container mounts volume at /var/log
# Points: 2

NS="sidecar-logging"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
MP=$(jp pod logger-pod "$NS" '.spec.containers[?(@.name=="app")].volumeMounts[?(@.name=="shared-log")].mountPath')
expect_equals "$MP" "/var/log" \
  "App container mounts shared-log at /var/log" \
  "App container mountPath is '$MP', expected '/var/log'"
