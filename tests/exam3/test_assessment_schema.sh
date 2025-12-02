#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "$0")/../.." && pwd)"
assess="$root_dir/facilitator/assets/exams/ckad/003/assessment.json"
val_dir="$root_dir/facilitator/assets/exams/ckad/003/scripts/validation"

command -v jq >/dev/null 2>&1 || { echo "jq is required for this test" >&2; exit 1; }

[ -f "$assess" ] || { echo "assessment.json not found" >&2; exit 1; }

len=$(jq '.questions | length' "$assess")
if [[ "$len" -ne 22 ]]; then
  echo "Expected 22 questions, found $len" >&2
  exit 1
fi

# Validate each question has required fields and scripts exist
for i in $(seq 0 21); do
  id=$(jq -r ".questions[$i].id" "$assess")
  ns=$(jq -r ".questions[$i].namespace" "$assess")
  mh=$(jq -r ".questions[$i].machineHostname" "$assess")
  qtext=$(jq -r ".questions[$i].question" "$assess")
  [ -n "$id" ] && [ -n "$ns" ] && [ -n "$mh" ] && [ -n "$qtext" ] || { echo "Missing fields in question index $i" >&2; exit 1; }

  # Check verification scripts exist
  vcount=$(jq ".questions[$i].verification | length" "$assess")
  for j in $(seq 0 $((vcount-1))); do
    script=$(jq -r ".questions[$i].verification[$j].verificationScriptFile" "$assess")
    [ -f "$val_dir/$script" ] || { echo "Missing validation script: $script (Q$id)" >&2; exit 1; }
  done
done

exit 0

