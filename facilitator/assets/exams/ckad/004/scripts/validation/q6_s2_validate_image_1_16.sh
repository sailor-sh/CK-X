#!/usr/bin/env bash
# Q06.02 - Image is nginx:1.16
# Points: 2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

NS="deployments-scaling"
IMG=$(jp deploy web-deploy "$NS" .spec.template.spec.containers[0].image)
expect_equals "$IMG" "nginx:1.16" \
  "Deployment uses image nginx:1.16" \
  "Deployment image is '$IMG', expected 'nginx:1.16'"
