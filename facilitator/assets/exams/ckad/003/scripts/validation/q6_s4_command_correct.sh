#!/bin/bash
# Validator for Q6 - Container Command (effect-based, startup-verification)
# Goal: verify the container itself created the ready flag during startup.
# Policy: be flexible with syntax; accept common equivalents beyond
#         strictly "touch /tmp/ready && sleep ...".

set -e

NS=readiness
POD=pod6
READY_PATH=/tmp/ready

# Ensure the pod exists before attempting exec
kubectl -n "$NS" get pod "$POD" >/dev/null 2>&1 || exit 1

# 1) The ready flag must exist
kubectl -n "$NS" exec "$POD" -- sh -c "test -f $READY_PATH" >/dev/null 2>&1 || exit 1

# Helper: match common creators or explicit path reference
matches_creator_or_path() {
  echo "$1" | grep -qE "/tmp/ready|\\b(touch|echo|printf|install|tee)\\b"
}

# 2) Runtime PID 1 cmdline evidence (first preference)
CMDLINE=$(kubectl -n "$NS" exec "$POD" -- sh -c "cat /proc/1/cmdline | tr '\\0' ' '" 2>/dev/null || true)
if matches_creator_or_path "$CMDLINE"; then
  exit 0
fi

# 3) Fallback: Inspect the pod spec command/args (covers cases like `exec sleep 1d` where PID 1 no longer shows the creator)
SPEC_CMD=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.containers[0].command[*]} {.spec.containers[0].args[*]}' 2>/dev/null || true)
if matches_creator_or_path "$SPEC_CMD"; then
  exit 0
fi

# 4) Fallback: Accept lifecycle postStart exec creating the file (still container-owned startup action)
POST_START=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.containers[0].lifecycle.postStart.exec.command[*]}' 2>/dev/null || true)
if matches_creator_or_path "$POST_START"; then
  exit 0
fi

# If nothing matched, consider it not created during startup
exit 1
