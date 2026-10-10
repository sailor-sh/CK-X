#!/usr/bin/env bash
set -euo pipefail
# Validates the sidecar container command is 'tail -f /var/log/cleaner/cleaner.log'
SIDECAR_COMMAND=$(kubectl -n sidecar-logging get deploy cleaner -o jsonpath='{.spec.template.spec.containers[?(@.name=="logger-con")].command}')
expected_command="tail -f /var/log/cleaner/cleaner.log"
if [ "$SIDECAR_COMMAND" != "$expected_command" ]; then
    echo "Sidecar command is $SIDECAR_COMMAND, expected $expected_command"
    exit 1
fi