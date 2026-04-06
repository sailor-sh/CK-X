#!/usr/bin/env bash
set -euo pipefail
# Validates the liveness probe's periodSeconds is 15
PERIOD=$(kubectl -n p1-liveness get deploy project-23-api -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.periodSeconds}')

if [ "$PERIOD" != "15" ]; then
    echo "Liveness probe periodSeconds is $PERIOD, expected 15"
    exit 1
fi