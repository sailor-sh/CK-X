#!/usr/bin/env bash
set -euo pipefail
type=$(kubectl -n nodeport-30100 get svc jupiter-crew-svc -o jsonpath='{.spec.type}')
test "$type" = "NodePort"
