#!/bin/bash
# Q20.03 - Volume is writable
# Points: 4

NS="persistent-storage"
# Try to write a test file to the mounted volume
ekubectl exec storage-pod -n "$NS" -- sh -c 'echo "test" > /data/testfile && rm /data/testfile' 2>/dev/null && {
  echo "✓ Volume is writable"
  exit 0
} || {
  echo "✗ Volume is not writable"
  exit 1
}