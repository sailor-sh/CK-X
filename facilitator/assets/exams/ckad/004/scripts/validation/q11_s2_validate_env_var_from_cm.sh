#!/usr/bin/env bash
# Q11.02 - Pod has MODE env var from ConfigMap
# Points: 4

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

NS="configmaps-env"
NAME=$(jp pod cm-pod "$NS" '.spec.containers[0].env[?(@.name=="MODE")].valueFrom.configMapKeyRef.name')
KEY=$(jp pod cm-pod "$NS" '.spec.containers[0].env[?(@.name=="MODE")].valueFrom.configMapKeyRef.key')
if [[ "$NAME" == "app-config" && -n "$KEY" ]]; then
  ok "MODE env var sourced from ConfigMap app-config"
else
  fail "MODE env var not sourced from expected ConfigMap"
fi
