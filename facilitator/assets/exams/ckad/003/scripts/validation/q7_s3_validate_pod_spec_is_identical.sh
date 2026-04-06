#!/usr/bin/env bash
set -euo pipefail
# This script validates that the pod in the target namespace uses the expected image.
# Assuming the original image for webserver-sat-003 was 'nginx:alpine'.
kubectl -n pod-move-target get pod webserver-sat-003 -o jsonpath='{.spec.containers[0].image}' | grep -q 'nginx:alpine'
