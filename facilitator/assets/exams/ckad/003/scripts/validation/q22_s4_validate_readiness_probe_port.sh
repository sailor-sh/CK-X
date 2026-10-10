#!/usr/bin/env bash
set -euo pipefail
# Validates that the readiness probe is targeting the correct port
PROBE_PORT=$(kubectl -n p3-readiness get deploy earth-3cc-web -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.port}')

if [ "$PROBE_PORT" != "80" ]; then
    echo "Readiness probe port is $PROBE_PORT, expected 80"
    exit 1
fi