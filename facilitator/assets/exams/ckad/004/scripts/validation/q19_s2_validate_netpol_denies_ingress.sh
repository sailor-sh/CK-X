#!/usr/bin/env bash
# Q19.02 - NetworkPolicy denies ingress (no ingress rules)
# Points: 4

NS="network-policies"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
ING=$(jp networkpolicy default-deny "$NS" .spec.ingress)
PT=$(jp networkpolicy default-deny "$NS" .spec.policyTypes[*])
if echo "$PT" | grep -q "Ingress" && [[ -z "$ING" ]]; then
  ok "Policy denies ingress (no ingress rules defined)"
else
  fail "Policy may not deny ingress (policyTypes=$PT, ingress=$ING)"
fi
