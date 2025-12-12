#!/bin/bash
# Q16.04 - 3 replicas ready
# Points: 2

READY=$(kubectl get statefulset mysql -n q16 -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
[[ "$READY" == "3" ]] && {
  echo "✓ 3 replicas ready"
  exit 0
} || {
  echo "✗ Ready replicas: $READY, expected 3"
  exit 1
}
