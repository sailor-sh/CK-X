#!/usr/bin/env bash
set -euo pipefail
# Ensures the service still has endpoints after the change
ENDPOINTS=$(kubectl -n nodeport-30100 get endpoints jupiter-crew-svc -o jsonpath='{.subsets[0].addresses}')

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