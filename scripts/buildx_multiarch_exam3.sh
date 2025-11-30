#!/usr/bin/env bash
set -euo pipefail

# Build and push multi-arch (amd64+arm64) images for Exam 3
#
# Usage:
#   export DOCKERHUB_NAMESPACE=je01
#   export VERSION=exam3-v1
#   ./scripts/buildx_multiarch_exam3.sh
#
# Prereqs:
#   - Docker Buildx available: docker buildx version
#   - Logged in to Docker Hub: docker login
#   - binfmt/qemu installed (the script will try to install via tonistiigi/binfmt)

NAMESPACE=${DOCKERHUB_NAMESPACE:-}
VERSION=${VERSION:-}

if [[ -z "$NAMESPACE" || -z "$VERSION" ]]; then
  echo "Set DOCKERHUB_NAMESPACE and VERSION env vars first." >&2
  echo "Example: DOCKERHUB_NAMESPACE=je01 VERSION=exam3-v1 ./scripts/buildx_multiarch_exam3.sh" >&2
  exit 1
fi

echo "Building multi-arch images: namespace=$NAMESPACE tag=$VERSION"

# Ensure binfmt is installed for cross-building
if ! docker run --privileged --rm tonistiigi/binfmt --version >/dev/null 2>&1; then
  echo "Installing binfmt for cross-building (requires privileged)..."
  docker run --privileged --rm tonistiigi/binfmt --install all
fi

# Ensure a buildx builder exists
if ! docker buildx ls | grep -q '^ckx-builder'; then
  echo "Creating buildx builder 'ckx-builder'..."
  docker buildx create --name ckx-builder --use
fi

PLATFORMS=linux/amd64,linux/arm64

build_push() {
  local context=$1 image=$2 dockerfile=${3:-}
  echo "\n==> Building $image from $context ${dockerfile:+(Dockerfile: $dockerfile)}"
  if [[ -n "$dockerfile" ]]; then
    docker buildx build \
      --platform "$PLATFORMS" \
      -t "$image" \
      -f "$dockerfile" \
      --push \
      "$context"
  else
    docker buildx build \
      --platform "$PLATFORMS" \
      -t "$image" \
      --push \
      "$context"
  fi
}

# remote-desktop
build_push ./remote-desktop "$NAMESPACE/ckx-remote-desktop:$VERSION"

# webapp
build_push ./app "$NAMESPACE/ckx-webapp:$VERSION"

# nginx
build_push ./nginx "$NAMESPACE/ckx-nginx:$VERSION"

# jumphost
build_push ./jumphost "$NAMESPACE/ckx-jumphost:$VERSION"

# remote-terminal
build_push ./remote-terminal "$NAMESPACE/ckx-remote-terminal:$VERSION"

# kind-cluster
build_push ./kind-cluster "$NAMESPACE/ckx-cluster:$VERSION"

# facilitator (Node/Facilitator API)
if [[ -f facilitator/Dockerfile ]]; then
  build_push . "$NAMESPACE/ckx-facilitator:$VERSION" facilitator/Dockerfile
else
  # Fallback to kubelingo/Dockerfile.facilitator if facilitator Dockerfile not present
  build_push . "$NAMESPACE/ckx-facilitator:$VERSION" kubelingo/Dockerfile.facilitator
fi

cat <<EOF

=====================================================
Compose override (multi-arch images, no platform pin)
=====================================================
Save as docker-compose.override.yaml to pull the new images:

services:
  remote-desktop:
    image: $NAMESPACE/ckx-remote-desktop:$VERSION
    build: null

  webapp:
    image: $NAMESPACE/ckx-webapp:$VERSION
    build: null

  nginx:
    image: $NAMESPACE/ckx-nginx:$VERSION
    build: null

  jumphost:
    image: $NAMESPACE/ckx-jumphost:$VERSION
    build: null

  remote-terminal:
    image: $NAMESPACE/ckx-remote-terminal:$VERSION
    build: null

  k8s-api-server:
    image: $NAMESPACE/ckx-cluster:$VERSION
    build: null

  facilitator:
    image: $NAMESPACE/ckx-facilitator:$VERSION
    build: null

EOF

echo "Done. Run: docker compose up -d"
