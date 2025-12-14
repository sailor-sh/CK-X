#!/usr/bin/env bash
set -euo pipefail

# Build and push the facilitator image (ARM64 only) with exam assets baked in.
# Simplified usage:
#   scripts/release/release-facilitator.sh <namespace> [tag]
#   - <namespace>: your Docker Hub or GHCR namespace (e.g., je01)
#   - [tag]: optional image tag (default: latest)
#
# Env overrides (optional):
#   REGISTRY=docker.io|ghcr.io (default: docker.io)
#   IMAGE_NAME=ckx-facilitator (default)
#   WRITE_ENV=1 (append/update CKX_FACILITATOR_IMAGE in .env)
#
# Requires:
#   - docker buildx (docker 20.10+)
#   - docker login to the target registry

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"/..
cd "$ROOT_DIR"

REGISTRY=${REGISTRY:-docker.io}
IMAGE_NAME=${IMAGE_NAME:-ckx-facilitator}
PLATFORM="linux/arm64"

# Accept positional args or envs; normalize namespace to lowercase
NS_INPUT=${1:-${IMAGE_NS:-${DOCKER_HUB_USERNAME:-}}}
TAG_INPUT=${2:-${IMAGE_TAG:-latest}}

if [ -z "${NS_INPUT}" ]; then
  echo "Usage: $0 <namespace> [tag]" >&2
  echo "Example: REGISTRY=docker.io $0 je01 exam3-v1" >&2
  exit 1
fi

# Normalize to lowercase for Docker registries
IMAGE_NS=$(echo -n "$NS_INPUT" | tr '[:upper:]' '[:lower:]')
IMAGE_TAG=$(echo -n "$TAG_INPUT" | tr '[:upper:]' '[:lower:]')

IMAGE_REF="${REGISTRY}/${IMAGE_NS}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "[release] Building ${IMAGE_REF} for ${PLATFORM}..."

# Ensure buildx builder exists
docker buildx inspect ckx-builder >/dev/null 2>&1 || docker buildx create --name ckx-builder --use

docker buildx build \
  --platform "${PLATFORM}" \
  -t "${IMAGE_REF}" \
  --push \
  facilitator

echo "[release] Pushed: ${IMAGE_REF}"

if [ "${WRITE_ENV:-0}" = "1" ]; then
  # Update or append CKX_FACILITATOR_IMAGE in .env
  if [ -f .env ]; then
    if grep -q '^CKX_FACILITATOR_IMAGE=' .env; then
      sed -i.bak "s|^CKX_FACILITATOR_IMAGE=.*$|CKX_FACILITATOR_IMAGE=${IMAGE_REF}|" .env && rm -f .env.bak
    else
      echo "CKX_FACILITATOR_IMAGE=${IMAGE_REF}" >> .env
    fi
  else
    echo "CKX_FACILITATOR_IMAGE=${IMAGE_REF}" > .env
  fi
  echo "[release] Wrote CKX_FACILITATOR_IMAGE to .env"
fi

cat <<EOF

[release] To use it locally now:
  export CKX_FACILITATOR_IMAGE=${IMAGE_REF}
  docker compose pull facilitator
  docker compose up -d facilitator

Or add CKX_FACILITATOR_IMAGE to .env and run:
  docker compose up -d

EOF
