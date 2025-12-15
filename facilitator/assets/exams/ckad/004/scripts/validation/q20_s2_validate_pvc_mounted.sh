#!/bin/bash
# Q20.02 - PVC mounted at /data in pod storage-pod
# Points: 3

NS="persistent-storage"
MOUNT=$(kubectl get pod storage-pod -n "$NS" -o jsonpath='{range .spec.containers[0].volumeMounts[?(@.mountPath=="/data")]}{.name}{end}' 2>/dev/null)
if [ -n "$MOUNT" ]; then
  echo "✓ PVC mounted at /data"
  exit 0
else
  echo "✗ PVC not mounted at /data"
  exit 1
fi

