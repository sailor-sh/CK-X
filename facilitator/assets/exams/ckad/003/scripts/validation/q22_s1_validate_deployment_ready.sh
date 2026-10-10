#!/usr/bin/env bash
set -euo pipefail
desired=$(kubectl -n p3-readiness get deploy earth-3cc-web -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
ready=$(kubectl -n p3-readiness get deploy earth-3cc-web -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
test "${desired}" = "${ready}" && test "${ready}" != "0"
