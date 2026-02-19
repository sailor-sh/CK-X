#!/usr/bin/env bash
set -euo pipefail
# Ensures the 'earth-3cc-web-svc' service has endpoints after the fix
ENDPOINTS=$(kubectl -n p3-readiness get endpoints earth-3cc-web-svc -o jsonpath='{.subsets[0].addresses}')

if [ -z "$ENDPOINTS" ]; then
    echo "Service has no endpoints"
    exit 1
fi

# Also check that endpoints are not empty
ENDPOINT_COUNT=$(echo "$ENDPOINTS" | jq '. | length')
if [ "$ENDPOINT_COUNT" -eq 0 ]; then
    echo "Service endpoints are empty"
    exit 1
fi