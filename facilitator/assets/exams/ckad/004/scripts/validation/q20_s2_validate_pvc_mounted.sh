#!/usr/bin/env bash
# Q20.02 - PVC mounted in pod at /data
# Points: 3

NS="persistent-storage"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
MOUNT=$(jp pod storage-pod "$NS" '.spec.containers[0].volumeMounts[?(@.name=="data-volume")].mountPath')
expect_equals "$MOUNT" "/data" \
  "PVC mounted at /data in storage-pod" \
  "PVC not mounted at /data (found: $MOUNT)"
