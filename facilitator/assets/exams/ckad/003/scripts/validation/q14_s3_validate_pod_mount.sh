#!/usr/bin/env bash
set -euo pipefail
ns=secrets-cm
name=secret-handler
# Verify a volume mounts ConfigMap "configmap1" at /tmp/secret2 on any container

# Find all volumeMount names across all containers that use mountPath=/tmp/secret2
mountNames=$(kubectl -n "$ns" get pod "$name" -o jsonpath='{.spec.containers[*].volumeMounts[?(@.mountPath=="/tmp/configmap1")].name}')

# If no mounts found, fail early
if [ -z "${mountNames}" ]; then
  exit 1
fi

# For any matching mount name, confirm the backing volume is a ConfigMap named "configmap1"
for m in ${mountNames}; do
  cmNameForMount=$(kubectl -n "$ns" get pod "$name" -o jsonpath="{.spec.volumes[?(@.name==\"$m\")].configMap.name}")
  if [ "$cmNameForMount" = "configmap1" ]; then
    exit 0
  fi
done

exit 1
