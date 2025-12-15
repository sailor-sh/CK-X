#!/usr/bin/env bash
# Q12.02 - Secret mounted at /etc/app-secret
# Points: 3

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

NS="secrets-volume"
VOL_NAME=$(jp pod sec-pod "$NS" '.spec.volumes[?(@.secret.secretName=="app-secret")].name')
MOUNT_NAME=$(jp pod sec-pod "$NS" '.spec.containers[0].volumeMounts[?(@.mountPath=="/etc/app-secret")].name')
if [[ -n "$VOL_NAME" && -n "$MOUNT_NAME" ]]; then
  ok "Secret app-secret mounted at /etc/app-secret"
else
  fail "Secret app-secret not mounted at /etc/app-secret"
fi
