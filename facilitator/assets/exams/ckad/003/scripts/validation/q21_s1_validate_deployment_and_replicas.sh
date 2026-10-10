#!/usr/bin/env bash
set -euo pipefail
kubectl -n p2-deploy-svc get deploy sunny -o name >/dev/null
rep=$(kubectl -n p2-deploy-svc get deploy sunny -o jsonpath='{.spec.replicas}')
test "$rep" = "4"
