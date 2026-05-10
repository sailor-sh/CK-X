#!/usr/bin/env bash
set -euo pipefail

# Require helm
if ! command -v helm >/dev/null 2>&1; then
  echo "helm not found" >&2
  exit 1
fi

# Ensure there are no releases stuck in pending-install across namespaces
if helm ls -A 2>/dev/null | awk 'NR>1 {print tolower($0)}' | grep -q "pending-install"; then
  exit 1
fi
exit 0
