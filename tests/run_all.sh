#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root_dir"

fail=0

run() {
  local name="$1"; shift
  echo "[TEST] $name"
  if bash "$@"; then
    echo "[PASS] $name"
  else
    echo "[FAIL] $name" >&2
    fail=1
  fi
  echo
}

run "Makefile targets present" tests/test_makefile.sh
run "Exam3 assessment schema" tests/exam3/test_assessment_schema.sh
run "Exam3 paths and conventions" tests/exam3/test_paths_and_conventions.sh
run "Exam3 registration in labs.json" tests/exam3/test_registration.sh
run "Answers presence" tests/exam3/test_answers.sh
run "Setup scripts sanity" tests/exam3/test_setup_scripts.sh

exit $fail

