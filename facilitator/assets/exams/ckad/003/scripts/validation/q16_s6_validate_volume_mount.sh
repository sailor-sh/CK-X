#!/usr/bin/env bash
set -euo pipefail
# Ensures the sidecar shares the volume mount with the main container
# Check if logger-con has the logs volume mount
LOGGER_VOLUME_MOUNT=$(kubectl -n sidecar-logging get deploy cleaner -o jsonpath='{.spec.template.spec.containers[?(@.name=="logger-con")].volumeMounts[?(@.name=="logs")].mountPath}')
if [ -z "$LOGGER_VOLUME_MOUNT" ]; then
    echo "Sidecar container does not have logs volume mount"
    exit 1
fi

# Check if the mount path is correct
if [ "$LOGGER_VOLUME_MOUNT" != "/var/log/cleaner" ]; then
    echo "Sidecar volume mount path is $LOGGER_VOLUME_MOUNT, expected /var/log/cleaner"
    exit 1
fi