#!/usr/bin/env bash
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found; this question requires Docker" >&2
  exit 1
fi

# Require local image tag to exist
docker images --format '{{.Repository}}:{{.Tag}}' | grep -q '^localhost:5000/sun-cipher:v1-docker$' || {
  echo "expected local tag localhost:5000/sun-cipher:v1-docker not found"; exit 1;
}
exit 0
