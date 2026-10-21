#!/usr/bin/env bash
set -euo pipefail

# Validate that the Service endpoints expose the expected target port (4444)
# This ensures the selector is fixed AND the targetPort matches the containerPort.

port=$(kubectl -n svc-fix-endpoints get endpoints manager-api-svc -o jsonpath='{.subsets[*].ports[*].port}' 2>/dev/null || true)

test "${port}" = "4444"
