#!/usr/bin/env bash
# Q08.01 - Image reverted to nginx:1.16
# Points: 5

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

NS="rollbacks"
IMG=$(jp deploy web-deploy "$NS" .spec.template.spec.containers[0].image)
expect_equals "$IMG" "nginx:1.16" \
  "Deployment image reverted to nginx:1.16" \
  "Deployment image is '$IMG', expected 'nginx:1.16'"
