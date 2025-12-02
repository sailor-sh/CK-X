#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "$0")/../.." && pwd)"
assess="$root_dir/facilitator/assets/exams/ckad/003/assessment.json"

command -v jq >/dev/null 2>&1 || { echo "jq is required for this test" >&2; exit 1; }
[ -f "$assess" ] || { echo "assessment.json not found" >&2; exit 1; }

# All namespaces follow ckad-qNN format
bad_ns=$(jq -r '.questions[].namespace' "$assess" | grep -vE '^ckad-q[0-9]{2}$' || true)
if [[ -n "$bad_ns" ]]; then
  echo "Namespaces not matching ckad-qNN:" >&2
  echo "$bad_ns" >&2
  exit 1
fi

# All file outputs reference /opt/course/exam3/qNN or /opt/course/exam3/pN
bad_paths=$(jq -r '.questions[].question' "$assess" | grep -Eo '/opt/course/[^ ]+' | grep -vE '^/opt/course/exam3/(q[0-9]{2}|p[1-3])/' || true)
if [[ -n "$bad_paths" ]]; then
  echo "Found non-standard output paths:" >&2
  echo "$bad_paths" >&2
  exit 1
fi

exit 0

