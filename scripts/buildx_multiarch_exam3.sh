#!/usr/bin/env bash
set -euo pipefail

# Build and push multi-arch (amd64+arm64) images for Exam 3
# Usage:
#   DOCKERHUB_NAMESPACE=<ns> VERSION=<tag> bash scripts/buildx_multiarch_exam3.sh

NAMESPACE=${DOCKERHUB_NAMESPACE:-}
VERSION=${VERSION:-}
PLATFORMS=${PLATFORMS:-linux/amd64,linux/arm64}
SKIP_PUSH=${SKIP_PUSH:-}

if [[ -z "$NAMESPACE" || -z "$VERSION" ]]; then
  echo "Set DOCKERHUB_NAMESPACE and VERSION env vars first." >&2
  echo "Example: DOCKERHUB_NAMESPACE=je01 VERSION=exam3-v2 make release-exam3" >&2
  exit 1
fi

echo "Building multi-arch images: namespace=$NAMESPACE tag=$VERSION platforms=$PLATFORMS"

# Decide push vs load behavior
PUSH_ARGS=(--push)
if [[ -n "$SKIP_PUSH" ]]; then
  host_arch=$(uname -m)
  case "$host_arch" in
    x86_64) host_platform=linux/amd64 ;;
    aarch64|arm64) host_platform=linux/arm64 ;;
    *) host_platform=linux/amd64 ;;
  esac
  if [[ "$PLATFORMS" == *","* ]]; then
    echo "[WARN] SKIP_PUSH set with multiple platforms ($PLATFORMS). Using host platform: $host_platform" >&2
    PLATFORMS="$host_platform"
  fi
  PUSH_ARGS=(--load)
fi

# Ensure binfmt for cross-building
if ! docker run --privileged --rm tonistiigi/binfmt --version >/dev/null 2>&1; then
  echo "Installing binfmt for cross-building (requires privileged)..."
  docker run --privileged --rm tonistiigi/binfmt --install all
fi

# Ensure a buildx builder exists and is selected
if docker buildx ls | grep -q '^ckx-builder'; then
  docker buildx use ckx-builder >/dev/null 2>&1 || true
else
  echo "Creating buildx builder 'ckx-builder'..."
  docker buildx create --name ckx-builder --use
fi

build() {
  local context=$1 image=$2 dockerfile=${3:-}
  echo "\n==> Building $image from $context ${dockerfile:+(Dockerfile: $dockerfile)}"
  if [[ -n "$dockerfile" ]]; then
    docker buildx build \
      --platform "$PLATFORMS" \
      -t "$image" \
      -f "$dockerfile" \
      "${PUSH_ARGS[@]}" \
      "$context"
  else
    docker buildx build \
      --platform "$PLATFORMS" \
      -t "$image" \
      "${PUSH_ARGS[@]}" \
      "$context"
  fi
}

# remote-desktop
build ./remote-desktop "$NAMESPACE/ckx-remote-desktop:$VERSION"

# webapp
build ./app "$NAMESPACE/ckx-webapp:$VERSION"

# nginx
build ./nginx "$NAMESPACE/ckx-nginx:$VERSION"

# jumphost
build ./jumphost "$NAMESPACE/ckx-jumphost:$VERSION"

# remote-terminal
build ./remote-terminal "$NAMESPACE/ckx-remote-terminal:$VERSION"

# kind-cluster
build ./kind-cluster "$NAMESPACE/ckx-cluster:$VERSION"

# facilitator (API)
if [[ -f facilitator/Dockerfile ]]; then
  build ./facilitator "$NAMESPACE/ckx-facilitator:$VERSION"
fi

if [[ -n "$SKIP_PUSH" ]]; then
  echo "\nDone. Images built locally with tag $VERSION (not pushed)"
else
  echo "\nDone. Images pushed under $NAMESPACE with tag $VERSION"
fi
