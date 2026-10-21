#!/usr/bin/env bash
set -euo pipefail
# Validates the init container's command writes the correct content to '/usr/share/nginx/html/index.html'
# Check if the command contains the expected content
INIT_COMMAND=$(kubectl -n init-container get deploy test-init-container -o jsonpath='{.spec.template.spec.initContainers[?(@.name=="init-con")].command}')
if [[ "$INIT_COMMAND" != *"check this out!"* ]]; then
    echo "Init container command does not contain expected content: $INIT_COMMAND"
    exit 1
fi

# Also check if it writes to the correct path
if [[ "$INIT_COMMAND" != *"/usr/share/nginx/html/index.html"* ]]; then
    echo "Init container command does not write to /usr/share/nginx/html/index.html: $INIT_COMMAND"
    exit 1
fi