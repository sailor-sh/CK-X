#!/usr/bin/env bash
set -euo pipefail
TYPE=$(kubectl -n ckad-q19 get svc jupiter-crew-svc -o jsonpath='{.spec.type}')
test "$TYPE" = "NodePort"

