#!/usr/bin/env bash
set -euo pipefail

PV_NAME="earth-project-earthflower-pv"

hp=$(kubectl get pv "${PV_NAME}" -o jsonpath='{.spec.hostPath.path}')
[[ "${hp}" == "/Volumes/Data" ]] || { echo "PV hostPath.path is '${hp}', expected '/Volumes/Data'"; exit 1; }

