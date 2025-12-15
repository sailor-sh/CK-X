#!/usr/bin/env bash
# Q18.03 - Service endpoints populated
# Points: 4

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

NS="services-clusterip"
IPS=$(jp endpoints web-svc "$NS" '.subsets[*].addresses[*].ip')
COUNT=$(echo "$IPS" | wc -w | tr -d ' ')
if [[ -n "$COUNT" && "$COUNT" -ge 1 ]]; then
  ok "Service endpoints populated ($COUNT)"
else
  fail "No endpoints found for service web-svc"
fi
