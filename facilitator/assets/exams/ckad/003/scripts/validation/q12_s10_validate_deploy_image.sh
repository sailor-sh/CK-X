#!/usr/bin/env bash
set -euo pipefail

NS="storage-hostpath"
DEPLOY="project-earthflower"

img=$(kubectl -n "${NS}" get deploy "${DEPLOY}" -o jsonpath='{.spec.template.spec.containers[0].image}')
[[ "${img}" == "httpd:2.4.41-alpine" ]] || { echo "Deployment image is '${img}', expected 'httpd:2.4.41-alpine'"; exit 1; }

