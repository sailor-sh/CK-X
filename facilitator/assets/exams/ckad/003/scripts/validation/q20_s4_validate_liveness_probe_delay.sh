#!/usr/bin/env bash
set -euo pipefail
# Validates the liveness probe's initialDelaySeconds is 10
INITIAL_DELAY=$(kubectl -n p1-liveness get deploy project-23-api -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.initialDelaySeconds}')

if [ "$INITIAL_DELAY" != "10" ]; then
    echo "Liveness probe initialDelaySeconds is $INITIAL_DELAY, expected 10"
    exit 1
fi