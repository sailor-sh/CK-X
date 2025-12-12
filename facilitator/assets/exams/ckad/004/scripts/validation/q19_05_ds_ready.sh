#!/bin/bash
# Q19.05 - DaemonSet ready
# Points: 2

READY=$(kubectl get daemonset logging-daemon -n q19 -o jsonpath='{.status.numberReady}' 2>/dev/null)
[[ -n "$READY" ]] && {
  echo "✓ Ready: $READY"
  exit 0
} || {
  echo "✗ Not ready"
  exit 1
}
