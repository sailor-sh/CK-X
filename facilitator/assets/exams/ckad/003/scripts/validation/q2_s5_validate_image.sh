#!/usr/bin/env bash
set -euo pipefail
IMAGE=$(kubectl -n single-pod get pod pod1 -o jsonpath='{.spec.containers[0].image}')
if [ "$IMAGE" != "httpd:2.4.41-alpine" ]; then
  echo "Wrong image: $IMAGE"
  exit 1
fi
