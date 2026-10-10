#!/usr/bin/env bash
set -euo pipefail
ready=$(kubectl -n readiness get pod pod6 -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null || echo false)
test "$ready" = "true"
