#!/bin/bash
# Q19.01 - DaemonSet exists
# Points: 2

kubectl get daemonset logging-daemon -n q19 >/dev/null 2>&1 && {
  echo "✓ DaemonSet logging-daemon exists"
  exit 0
} || {
  echo "✗ DaemonSet not found"
  exit 1
}
