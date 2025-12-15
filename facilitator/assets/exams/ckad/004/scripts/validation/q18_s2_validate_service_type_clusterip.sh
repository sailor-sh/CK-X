#!/usr/bin/env bash
# Q18.02 - Service type is ClusterIP
# Points: 2

NS="services-clusterip"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
TYPE=$(jp svc web-svc "$NS" .spec.type)
expect_equals "$TYPE" "ClusterIP" \
  "Service type is ClusterIP" \
  "Service type is '$TYPE', expected 'ClusterIP'"
