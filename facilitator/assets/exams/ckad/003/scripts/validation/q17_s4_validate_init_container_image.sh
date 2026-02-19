#!/usr/bin/env bash
set -euo pipefail
# Validates the init container is using the 'busybox:1.31.0' image
INIT_IMAGE=$(kubectl -n init-container get deploy test-init-container -o jsonpath='{.spec.template.spec.initContainers[?(@.name=="init-con")].image}')
if [ -z "$INIT_IMAGE" ]; then
    echo "Init container 'init-con' not found or has no image specified"
    exit 1
fi
if [ "$INIT_IMAGE" != "busybox:1.31.0" ]; then
    echo "Init container image is $INIT_IMAGE, expected busybox:1.31.0"
    exit 1
fi