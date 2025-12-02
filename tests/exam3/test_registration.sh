#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "$0")/../.." && pwd)"
labs="$root_dir/facilitator/assets/exams/labs.json"

command -v jq >/dev/null 2>&1 || { echo "jq is required for this test" >&2; exit 1; }
[ -f "$labs" ] || { echo "labs.json not found" >&2; exit 1; }

# Check that ckad-003 exists and has correct assetPath
exists=$(jq -r '.labs[] | select(.id=="ckad-003") | .assetPath' "$labs")
if [[ "$exists" != "assets/exams/ckad/003" ]]; then
  echo "ckad-003 not registered correctly in labs.json" >&2
  exit 1
fi

exit 0

