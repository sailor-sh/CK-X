#!/usr/bin/env bash
# Q19.03 - Ingress traffic blocked (structural check)
# Points: 3

# Structural verification: default-deny with no ingress rules implies traffic blocked
NS="network-policies"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
ING=$(jp networkpolicy default-deny "$NS" .spec.ingress)
if [[ -z "$ING" ]]; then
  ok "No ingress rules present; ingress blocked by default"
else
  fail "Ingress rules present; not a default deny"
fi
