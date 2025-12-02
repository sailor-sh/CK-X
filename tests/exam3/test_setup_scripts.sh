#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "$0")/../.." && pwd)"
setup_dir="$root_dir/facilitator/assets/exams/ckad/003/scripts/setup"

[ -d "$setup_dir" ] || { echo "setup scripts directory not found" >&2; exit 1; }

# Ensure scripts are present for known questions
req=(q14_setup.sh q7_setup.sh q8_setup.sh q18_setup.sh)
for s in "${req[@]}"; do
  if [[ ! -f "$setup_dir/$s" ]]; then
    echo "Missing setup script: $s" >&2
    exit 1
  fi
done

# Ensure q14 uses wait for readiness to avoid races
grep -q "wait --for=condition=Ready" "$setup_dir/q14_setup.sh" || { echo "q14_setup.sh missing kubectl wait readiness" >&2; exit 1; }

exit 0

