#!/usr/bin/env bash
set -euo pipefail
NS=ckad-q04

# apiv1 should be deleted
if kubectl -n "$NS" get deploy internal-issue-report-apiv1 >/dev/null 2>&1; then
  echo "apiv1 still exists"; exit 1;
fi

# apiv2 should exist
kubectl -n "$NS" get deploy internal-issue-report-apiv2 >/dev/null 2>&1 || { echo "apiv2 missing"; exit 1; }

# apache should exist with 2 replicas
kubectl -n "$NS" get deploy internal-issue-report-apache >/dev/null 2>&1 || { echo "apache missing"; exit 1; }
R=$(kubectl -n "$NS" get deploy internal-issue-report-apache -o jsonpath='{.spec.replicas}')
test "$R" = "2" || { echo "apache replicas not 2"; exit 1; }
