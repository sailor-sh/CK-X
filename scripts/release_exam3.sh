#!/usr/bin/env bash
set -euo pipefail

# CK-X Release Script: Tag + Push all service images for Exam 3 as one unit
#
# This script tags the locally built CK-X images with your Docker Hub namespace
# and a single VERSION tag, pushes them, and writes a compose override file that
# pulls these images. It also writes a release manifest listing the pushed images
# with their digests.
#
# Usage:
#   export DOCKERHUB_NAMESPACE=je01
#   export VERSION=exam3-v1
#   # optional: export PUSH_PARALLEL=1
#   ./scripts/release_exam3.sh
#
# Prereqs:
#   - Images must exist locally (build via ./scripts/setup_exam3_local.sh)
#   - docker login must be completed (you can use a PAT)
#

NAMESPACE=${DOCKERHUB_NAMESPACE:-}
VERSION=${VERSION:-}
PAR=${PUSH_PARALLEL:-}

if [[ -z "$NAMESPACE" || -z "$VERSION" ]]; then
  echo "Set DOCKERHUB_NAMESPACE and VERSION env vars first." >&2
  echo "Example: DOCKERHUB_NAMESPACE=je01 VERSION=exam3-v1 ./scripts/release_exam3.sh" >&2
  exit 1
fi

IMAGES=(
  "nishanb/ck-x-simulator-remote-desktop:latest $NAMESPACE/ckx-remote-desktop:$VERSION"
  "nishanb/ck-x-simulator-webapp:latest $NAMESPACE/ckx-webapp:$VERSION"
  "nishanb/ck-x-simulator-nginx:latest $NAMESPACE/ckx-nginx:$VERSION"
  "nishanb/ck-x-simulator-jumphost:latest $NAMESPACE/ckx-jumphost:$VERSION"
  "nishanb/ck-x-simulator-remote-terminal:latest $NAMESPACE/ckx-remote-terminal:$VERSION"
  "nishanb/ck-x-simulator-cluster:latest $NAMESPACE/ckx-cluster:$VERSION"
  "ckx-facilitator-generated:latest $NAMESPACE/ckx-facilitator:$VERSION"
)

echo "Tagging and pushing images as unit: namespace=$NAMESPACE version=$VERSION"

tag_and_push() {
  local src=$1 dst=$2
  echo "---"
  echo "Tagging $src -> $dst"
  docker tag "$src" "$dst"
  echo "Pushing $dst"
  docker push "$dst"
}

if [[ -n "$PAR" ]]; then
  # Parallel push
  for ITEM in "${IMAGES[@]}"; do
    SRC=${ITEM%% *}
    DST=${ITEM#* }
    tag_and_push "$SRC" "$DST" &
  done
  wait
else
  # Serial push
  for ITEM in "${IMAGES[@]}"; do
    SRC=${ITEM%% *}
    DST=${ITEM#* }
    tag_and_push "$SRC" "$DST"
  done
fi

# Write release manifest with digests
mkdir -p release
MANIFEST="release/ckx-${VERSION}.json"
echo "[" > "$MANIFEST"
first=1
for ITEM in "${IMAGES[@]}"; do
  SRC=${ITEM%% *}
  DST=${ITEM#* }
  DIGEST=$(docker buildx imagetools inspect "$DST" | awk '/Digest:/ {print $2; exit}' || true)
  if [[ $first -eq 0 ]]; then echo "," >> "$MANIFEST"; fi
  first=0
  printf '  {"image":"%s","digest":"%s"}' "$DST" "${DIGEST:-unknown}" >> "$MANIFEST"
done
echo "]" >> "$MANIFEST"
echo "Wrote release manifest: $MANIFEST"

# Write compose override that pulls the published images
OVERRIDE="docker-compose.override.yaml"
cat > "$OVERRIDE" <<EOF
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

echo "Wrote compose override: $OVERRIDE"
echo "Done. Next: docker compose up -d"
