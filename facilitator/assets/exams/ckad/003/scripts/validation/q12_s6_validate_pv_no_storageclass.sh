#!/usr/bin/env bash
set -euo pipefail

PV_NAME="earth-project-earthflower-pv"

sc=$(kubectl get pv "${PV_NAME}" -o jsonpath='{.spec.storageClassName}' 2>/dev/null || true)
# Pass if empty or unset
if [[ -n "${sc}" ]]; then
  echo "PV storageClassName is set to '${sc}', expected none"
  exit 1
fi

