#!/usr/bin/env bash
set -euo pipefail

NS="storage-hostpath"
PVC_NAME="earth-project-earthflower-pvc"

req=$(kubectl -n "${NS}" get pvc "${PVC_NAME}" -o jsonpath='{.spec.resources.requests.storage}')
# More robust: print as a single line and search for word match
am=$(kubectl -n "${NS}" get pvc "${PVC_NAME}" -o jsonpath='{.spec.accessModes[*]}')

[[ "${req}" == "2Gi" ]] || { echo "PVC requested storage is '${req}', expected '2Gi'"; exit 1; }
echo "${am}" | grep -qw 'ReadWriteOnce' || { echo "PVC accessModes missing ReadWriteOnce"; exit 1; }
