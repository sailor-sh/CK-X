#!/usr/bin/env bash
set -euo pipefail

NS="storage-hostpath"
PVC_NAME="earth-project-earthflower-pvc"

sc=$(kubectl -n "${NS}" get pvc "${PVC_NAME}" -o jsonpath='{.spec.storageClassName}' 2>/dev/null || true)
# Accept empty or unset
if [[ -n "${sc}" ]]; then
  echo "PVC storageClassName is set to '${sc}', expected none"
  exit 1
fi

