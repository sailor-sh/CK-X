#!/usr/bin/env bash
set -euo pipefail
NP=$(kubectl -n ckad-q19 get svc jupiter-crew-svc -o jsonpath='{.spec.ports[0].nodePort}')
test "$NP" = "30100"

