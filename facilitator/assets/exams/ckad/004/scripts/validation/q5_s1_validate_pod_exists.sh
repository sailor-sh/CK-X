#!/usr/bin/env bash
# Q05.01 - All 3 pods (pod-a, pod-b, pod-c) exist
# Points: 2

NS="labels-selectors"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
missing=0
for p in pod-a pod-b pod-c; do
  if ! k_exists pod "$p" "$NS"; then
    echo "✗ Pod $p not found in $NS"
    missing=1
  fi
done

if [[ "$missing" -eq 0 ]]; then
  ok "All 3 pods exist in $NS"
else
  fail "One or more pods missing in $NS"
fi
