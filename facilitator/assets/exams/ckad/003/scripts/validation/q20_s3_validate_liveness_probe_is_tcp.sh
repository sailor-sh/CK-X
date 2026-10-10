#!/usr/bin/env bash
set -euo pipefail
# Validates the liveness probe is a TCP probe on port 80
PROBE_TYPE=$(kubectl -n p1-liveness get deploy project-23-api -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.tcp}')

if [ -z "$PROBE_TYPE" ]; then
    echo "Liveness probe is not a TCP probe"
    exit 1
fi

# Check if it's on port 80
PROBE_PORT=$(echo "$PROBE_TYPE" | jq -r '.port')
if [ "$PROBE_PORT" != "80" ]; then
    echo "Liveness probe TCP port is $PROBE_PORT, expected 80"
    exit 1
fi