#!/usr/bin/env bash
# Q07.02 - Image updated to nginx:1.17
# Points: 4

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

NS="rolling-updates"
IMG=$(jp deploy web-deploy "$NS" .spec.template.spec.containers[0].image)
expect_equals "$IMG" "nginx:1.17" \
  "Deployment image updated to nginx:1.17" \
  "Deployment image is '$IMG', expected 'nginx:1.17'"
