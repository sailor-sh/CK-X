#!/bin/bash
# Q07.05 - Pod mounts PVC
# Points: 2

PVC=$(kubectl get pod volume-pod -n q07 -o jsonpath='{.spec.volumes[0].persistentVolumeClaim.claimName}' 2>/dev/null)
[[ "$PVC" == "test-pvc" ]] && {
  echo "✓ Pod mounts test-pvc"
  exit 0
} || {
  echo "✗ Pod mounts $PVC, expected test-pvc"
  exit 1
}
