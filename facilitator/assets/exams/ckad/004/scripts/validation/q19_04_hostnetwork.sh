#!/bin/bash
# Q19.04 - Pod template correct
# Points: 2

HOSTNET=$(kubectl get daemonset logging-daemon -n q19 -o jsonpath='{.spec.template.spec.hostNetwork}' 2>/dev/null)
[[ "$HOSTNET" == "true" ]] && {
  echo "✓ HostNetwork enabled"
  exit 0
} || {
  echo "✗ HostNetwork not set"
  exit 1
}
