#!/usr/bin/env bash
set -euo pipefail
# Ensures the 'init-con' init container exists
INIT_CONTAINERS=$(kubectl -n init-container get deploy test-init-container -o jsonpath='{.spec.template.spec.initContainers[*].name}')
if [[ "$INIT_CONTAINERS" != *"init-con"* ]]; then
    echo "Init container 'init-con' not found in deployment"
    exit 1
fi