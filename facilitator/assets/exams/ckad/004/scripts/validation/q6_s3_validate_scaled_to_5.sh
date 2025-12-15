#!/usr/bin/env bash
# Q06.03 - Deployment scaled to 5 replicas
# Points: 4

NS="deployments-scaling"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"
REPL=$(jp deploy web-deploy "$NS" .spec.replicas)
expect_equals "$REPL" "5" \
  "Deployment scaled to 5 replicas" \
  "Deployment replicas is '$REPL', expected '5'"
