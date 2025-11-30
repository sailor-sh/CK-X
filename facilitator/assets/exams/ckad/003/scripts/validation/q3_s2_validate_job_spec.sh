#!/usr/bin/env bash
set -euo pipefail
NS=ckad-q03
JOB=neb-new-job
C=$(kubectl -n "$NS" get job "$JOB" -o jsonpath='{.spec.completions}')
P=$(kubectl -n "$NS" get job "$JOB" -o jsonpath='{.spec.parallelism}')
test "$C" = "3" && test "$P" = "2"

