#!/usr/bin/env bash
set -euo pipefail

# Ensure there are multiple revisions in rollout history so a rollback is meaningful
hist=$(kubectl -n rollout rollout history deploy/api-new-c32 2>/dev/null || true)
count=$(printf "%s\n" "$hist" | awk '/^[[:space:]]*[0-9]+[[:space:]]/ {c++} END {print c+0}')
test "$count" -ge 2

