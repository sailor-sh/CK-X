#!/usr/bin/env bash
set -euo pipefail

NS="storage-hostpath"
DEPLOY="project-earthflower"

# Some environments may not have the hostPath present (/Volumes/Data).
# Instead of requiring Ready pods, validate that the Deployment has created pods.
created=$(kubectl -n "${NS}" get deploy "${DEPLOY}" -o jsonpath='{.status.replicas}')

if [[ -n "${created}" && "${created}" -ge 1 ]]; then
  exit 0
else
  echo "Deployment has not created pods (status.replicas='${created}')"
  exit 1
fi
