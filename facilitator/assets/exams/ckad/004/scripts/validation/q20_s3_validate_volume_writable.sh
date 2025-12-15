#!/usr/bin/env bash
# Q20.03 - Volume is writable
# Points: 4

NS="persistent-storage"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
# Try to write a test file to the mounted volume
if kubectl exec storage-pod -n "$NS" -- sh -c 'echo "test" > /data/testfile && rm /data/testfile' 2>/dev/null; then
  ok "Volume is writable"
else
  fail "Volume is not writable"
fi
