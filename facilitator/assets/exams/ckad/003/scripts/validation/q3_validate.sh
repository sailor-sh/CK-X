#!/usr/bin/env bash
set -euo pipefail
NS=ckad-q03
JOB=neb-new-job
FILE=/opt/course/exam3/q03/job.yaml
kubectl -n "$NS" get job "$JOB" >/dev/null 2>&1 || { echo "job missing"; exit 1; }
C=$(kubectl -n "$NS" get job "$JOB" -o jsonpath='{.spec.completions}')
P=$(kubectl -n "$NS" get job "$JOB" -o jsonpath='{.spec.parallelism}')
test "$C" = "3" || { echo "wrong completions"; exit 1; }
test "$P" = "2" || { echo "wrong parallelism"; exit 1; }
test -f "$FILE" || { echo "job yaml missing"; exit 1; }
