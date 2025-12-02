#!/usr/bin/env bash
set -euo pipefail

FILE=Makefile
[ -f "$FILE" ] || { echo "Makefile not found" >&2; exit 1; }

req_targets=(up down restart pull reset reset-up check-answers release-exam3)
for t in "${req_targets[@]}"; do
  if ! grep -Eq "^${t}:" "$FILE"; then
    echo "Missing target: $t" >&2
    exit 1
  fi
done

# Ensure referenced scripts exist (executability not required; invoked via bash)
[ -f scripts/check_answers.sh ] || { echo "scripts/check_answers.sh missing" >&2; exit 1; }
[ -f scripts/buildx_multiarch_exam3.sh ] || { echo "scripts/buildx_multiarch_exam3.sh missing" >&2; exit 1; }

exit 0
