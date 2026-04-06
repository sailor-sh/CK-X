#!/usr/bin/env bash
set -euo pipefail
# Validates the sidecar container is using the 'busybox:1.31.0' image
SIDECAR_IMAGE=$(kubectl -n sidecar-logging get deploy cleaner -o jsonpath='{.spec.template.spec.containers[?(@.name=="logger-con")].image}')
if [ "$SIDECAR_IMAGE" != "busybox:1.31.0" ]; then
    echo "Sidecar image is $SIDECAR_IMAGE, expected busybox:1.31.0"
    exit 1
fi