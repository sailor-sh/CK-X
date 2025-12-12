#!/bin/bash
# Q19.02 - DaemonSet scheduled
# Points: 2

DESIRED=$(kubectl get daemonset logging-daemon -n q19 -o jsonpath='{.status.desiredNumberScheduled}' 2>/dev/null)
[[ -n "$DESIRED" ]] && {
  echo "✓ Scheduled on nodes"
  exit 0
} || {
  echo "✗ Not scheduled"
  exit 1
}
