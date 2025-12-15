#!/usr/bin/env bash
# Q21.03 - Helm created pods/services
# Points: 4

NS="helm-ns"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
PODS=$(kubectl get pods -n "$NS" --no-headers 2>/dev/null | wc -l | tr -d ' ')
SVCS=$(kubectl get services -n "$NS" --no-headers 2>/dev/null | wc -l | tr -d ' ')

if [[ "$PODS" -gt 0 && "$SVCS" -gt 0 ]]; then
  ok "Helm created pods and services in helm-ns"
else
  fail "Helm did not create expected resources (pods: $PODS, services: $SVCS)"
fi
