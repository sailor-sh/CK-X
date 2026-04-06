#!/usr/bin/env bash
set -euo pipefail

# Require helm
if ! command -v helm >/dev/null 2>&1; then
  echo "helm not found" >&2
  exit 1
fi

# Verify helm release exists
if ! helm list -n helm 2>/dev/null | awk 'NR>1 {print $1}' | grep -qx "internal-issue-report-apache"; then
  exit 1
fi

# Verify resulting Deployment has replicas=2
replicas=$(kubectl -n helm get deploy internal-issue-report-apache -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "")
test "$replicas" = "2"
