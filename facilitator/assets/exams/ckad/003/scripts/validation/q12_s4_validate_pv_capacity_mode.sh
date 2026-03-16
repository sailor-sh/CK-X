#!/usr/bin/env bash
set -euo pipefail

PV_NAME="earth-project-earthflower-pv"

cap=$(kubectl get pv "${PV_NAME}" -o jsonpath='{.spec.capacity.storage}')
# More robust: print as a single line and search for word match
am=$(kubectl get pv "${PV_NAME}" -o jsonpath='{.spec.accessModes[*]}')

[[ "${cap}" == "2Gi" ]] || { echo "PV capacity is '${cap}', expected '2Gi'"; exit 1; }
echo "${am}" | grep -qw 'ReadWriteOnce' || { echo "PV accessModes missing ReadWriteOnce"; exit 1; }
