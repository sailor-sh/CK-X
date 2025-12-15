#!/bin/bash
# Q20.03 - Volume is writable at /data
# Points: 4

NS="persistent-storage"
POD="storage-pod"
kubectl exec -n "$NS" "$POD" -- sh -c 'echo test > /data/.writetest && rm -f /data/.writetest' >/dev/null 2>&1 && {
  echo "✓ Volume at /data is writable"
  exit 0
} || {
  echo "✗ Failed to write to /data"
  exit 1
}

