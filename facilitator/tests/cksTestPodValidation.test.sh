#!/bin/bash
# Run with: bash facilitator/tests/cksTestPodValidation.test.sh
# The validator runs unchanged in a child shell; kubectl uses fixtures only.
set -eu

TEST_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
VALIDATOR="$TEST_DIR/../assets/exams/cks/001/scripts/validation/q4_s3_validate_test_pod.sh"

kubectl() {
  if [ "${1-}" != "get" ] || [ "${2-}" != "pod" ] ||
     [ "${3-}" != "test-pod" ] || [ "${4-}" != "-n" ] ||
     [ "${5-}" != "metadata-protect" ]; then
    echo "Unexpected kubectl arguments: $*" >&2
    return 2
  fi
  [ "$TEST_EXISTS" = "true" ] || return 1
  [ "$#" -gt 5 ] || return 0
  case "$7" in
    'jsonpath={.status.phase}') printf '%s' "$TEST_PHASE" ;;
    'jsonpath={.spec.containers[0].image}') printf '%s' "$TEST_IMAGE" ;;
    'jsonpath={.spec.containers[0].command}') printf '%s' "$TEST_COMMAND" ;;
    'jsonpath={.spec.containers[0].command} {.spec.containers[0].args}')
      printf '%s %s' "$TEST_COMMAND" "$TEST_ARGS"
      ;;
    *) echo "Unexpected kubectl output option: $7" >&2; return 2 ;;
  esac
}
export -f kubectl

FAILURES=0
check() {
  local name=$1 expected_status=$2 expected_output=$3 command=$4 args=$5
  local output status=0
  output=$(TEST_COMMAND="$command" TEST_ARGS="$args" TEST_PHASE="${6:-Running}" \
    TEST_IMAGE="${7:-busybox}" TEST_EXISTS="${8:-true}" bash "$VALIDATOR" 2>&1) || status=$?
  if [ "$status" -ne "$expected_status" ] || [[ "$output" != *"$expected_output"* ]]; then
    printf 'FAIL: %s (exit %s)\n%s\n' "$name" "$status" "$output" >&2
    FAILURES=$((FAILURES + 1))
  else
    printf 'PASS: %s\n' "$name"
  fi
}

check "sleep in command" 0 "correctly configured" '["sleep","3600"]' ''
check "sleep in args, as created by kubectl run" 0 "correctly configured" '' '["sleep","3600"]'
check "shell command with sleep in args" 0 "correctly configured" '["/bin/sh","-c"]' '["sleep 3600"]'
check "sleep command with separate duration" 0 "correctly configured" '["sleep"]' '["3600"]'
check "unrelated command and args" 1 "not running sleep command" '["echo"]' '["ready"]'
check "no command or args" 1 "not running sleep command" '' ''
check "pending pod" 1 "not in Running state" '' '["sleep","3600"]' Pending
check "wrong image" 1 "not using the busybox image" '' '["sleep","3600"]' Running nginx
check "missing pod" 1 "not found in namespace" '' '["sleep","3600"]' Running busybox false

[ "$FAILURES" -eq 0 ]
