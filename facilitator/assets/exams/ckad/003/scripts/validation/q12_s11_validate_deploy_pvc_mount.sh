#!/usr/bin/env bash
set -euo pipefail

NS="storage-hostpath"
DEPLOY="project-earthflower"
PVC="earth-project-earthflower-pvc"

# Verify a volume references the PVC
vol_name=$(kubectl -n "${NS}" get deploy "${DEPLOY}" -o jsonpath='{..volumes[?(@.persistentVolumeClaim.claimName=="'"${PVC}"'")].name}')

# Verify mount path exists and references same volume name
mount_vol=$(kubectl -n "${NS}" get deploy "${DEPLOY}" -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[?(@.mountPath=="/tmp/project-data")].name}')

[[ -n "${vol_name}" ]] || { echo "No volume found referencing PVC ${PVC}"; exit 1; }
[[ "${mount_vol}" == "${vol_name}" ]] || { echo "Mount path /tmp/project-data is not using PVC volume '${vol_name}' (found mount '${mount_vol}')"; exit 1; }

