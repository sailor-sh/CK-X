#!/usr/bin/env bash
set -euo pipefail

if ! command -v curl >/dev/null 2>&1; then
  echo "curl not found; required to query local registry" >&2
  exit 1
fi

# Require registry API to respond and include v1-docker tag
resp=$(curl -fsS http://localhost:5000/v2/sun-cipher/tags/list)
echo "$resp" | grep -Eq 'v1-docker' || { echo "expected docker tag not present in registry"; exit 1; }
exit 0
