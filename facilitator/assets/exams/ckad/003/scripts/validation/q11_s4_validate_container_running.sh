#!/usr/bin/env bash
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found; this question requires Docker" >&2
  exit 1
fi

# Require a running container named sun-cipher
if ! docker ps --format '{{.Names}}' | grep -qx 'sun-cipher'; then
  echo "sun-cipher container not running"; exit 1
fi

# Validate the image and tag of the running container
IMG_NAME=$(docker inspect --format '{{.Config.Image}}' sun-cipher 2>/dev/null || true)
echo "$IMG_NAME" | grep -q '^localhost:5000/sun-cipher' || { echo "container not using localhost:5000/sun-cipher image"; exit 1; }
echo "$IMG_NAME" | grep -Eq ':(v1-docker)$' || { echo "container tag not :v1-docker"; exit 1; }
exit 0
