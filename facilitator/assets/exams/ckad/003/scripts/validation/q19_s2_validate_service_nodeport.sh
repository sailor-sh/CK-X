#!/usr/bin/env bash
set -euo pipefail
np=$(kubectl -n nodeport-30100 get svc jupiter-crew-svc -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "")
test "$np" = "30100"
