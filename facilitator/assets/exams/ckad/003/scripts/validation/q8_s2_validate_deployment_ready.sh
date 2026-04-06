#!/usr/bin/env bash
set -euo pipefail

# Validate that the deployment has completed rollout of the current revision
# This ensures readiness corresponds to the up-to-date template, not an old replica.
kubectl -n rollout rollout status deploy/api-new-c32 --timeout=10s >/dev/null 2>&1
