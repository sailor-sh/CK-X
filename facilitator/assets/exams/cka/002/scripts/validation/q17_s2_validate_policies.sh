#!/bin/bash
set -e

# Helper to check if a policy exists
check_policy_exists() {
  local name=$1
  if ! kubectl get networkpolicy "$name" -n network >/dev/null 2>&1; then
    echo "❌ $name not found"
    exit 1
  fi
}

# Helper to check if a policy egress allows traffic to a given app
check_egress_to() {
  local policy=$1
  local app=$2
  local found=$(kubectl get networkpolicy "$policy" -n network -o jsonpath="{.spec.egress[*].to[*].podSelector.matchLabels.app}" | grep -w "$app" || true)
  if [[ -z "$found" ]]; then
    echo "❌ $policy does not allow egress to $app"
    exit 1
  fi
}

# Check required policies
check_policy_exists web-policy
check_policy_exists api-policy

# Check egress rules
check_egress_to web-policy api
check_egress_to api-policy db

echo "✅ NetworkPolicies validation successful"
exit 0
