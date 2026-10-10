#!/usr/bin/env bash
set -euo pipefail
comps=$(kubectl -n jobs get job neb-new-job -o jsonpath='{.spec.completions}')
test "$comps" = "3"
