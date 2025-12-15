#!/usr/bin/env bash
# Q06.04 - 5 pods are ready
# Points: 2

NS="deployments-scaling"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
SEL=$(kubectl get deploy web-deploy -n "$NS" -o jsonpath='{.spec.selector.matchLabels}' | sed 's/map\[//;s/\]//;s/ /,/g')
# Fallback: use app=web-deploy if selector not easily parsed
if [[ -z "$SEL" ]]; then
  READY=$(kubectl get pods -n "$NS" -l app=web-deploy -o jsonpath='{range .items[*]}{.status.containerStatuses[0].ready}{"\n"}{end}' 2>/dev/null | grep -c true)
else
  READY=$(kubectl get pods -n "$NS" -l "$SEL" -o jsonpath='{range .items[*]}{.status.containerStatuses[0].ready}{"\n"}{end}' 2>/dev/null | grep -c true)
fi

if [[ "$READY" -ge 5 ]]; then
  ok "At least 5 pods are Ready"
else
  fail "Ready pods: $READY, expected 5"
fi
