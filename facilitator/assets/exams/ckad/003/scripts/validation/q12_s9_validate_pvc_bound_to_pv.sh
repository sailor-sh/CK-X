#!/usr/bin/env bash
set -euo pipefail

NS="storage-hostpath"
PVC_NAME="earth-project-earthflower-pvc"
PV_NAME="earth-project-earthflower-pv"

phase=$(kubectl -n "${NS}" get pvc "${PVC_NAME}" -o jsonpath='{.status.phase}')
vol=$(kubectl -n "${NS}" get pvc "${PVC_NAME}" -o jsonpath='{.spec.volumeName}')

[[ "${phase}" == "Bound" ]] || { echo "PVC phase is '${phase}', expected 'Bound'"; exit 1; }
[[ "${vol}" == "${PV_NAME}" ]] || { echo "PVC bound to volume '${vol}', expected '${PV_NAME}'"; exit 1; }

