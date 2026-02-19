#!/usr/bin/env bash
set -euo pipefail
par=$(kubectl -n jobs get job neb-new-job -o jsonpath='{.spec.parallelism}')
test "$par" = "2"
