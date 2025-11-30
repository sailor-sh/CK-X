#!/usr/bin/env bash
set -euo pipefail

# Publish locally built CK-X images to Docker Hub for faster startup
#
# Usage:
#   DOCKERHUB_NAMESPACE=myuser VERSION=exam3-v1 ./scripts/publish_images.sh
#
# Notes:
# - Assumes images have already been built by docker compose (e.g., via setup_exam3_local.sh)
# - You must be logged in: `docker login`
# - Produces tags under: $DOCKERHUB_NAMESPACE/ckx-<component>:$VERSION

NAMESPACE=${DOCKERHUB_NAMESPACE:-}
VERSION=${VERSION:-latest}

if [[ -z "$NAMESPACE" ]]; then
  echo "Set DOCKERHUB_NAMESPACE env var (e.g., export DOCKERHUB_NAMESPACE=myuser)" >&2
  exit 1
fi

echo "Publishing CK-X images to Docker Hub namespace: $NAMESPACE (tag: $VERSION)"

declare -A MAP=(
  ["nishanb/ck-x-simulator-remote-desktop:latest"]="$NAMESPACE/ckx-remote-desktop:$VERSION"
  ["nishanb/ck-x-simulator-webapp:latest"]="$NAMESPACE/ckx-webapp:$VERSION"
  ["nishanb/ck-x-simulator-nginx:latest"]="$NAMESPACE/ckx-nginx:$VERSION"
  ["nishanb/ck-x-simulator-jumphost:latest"]="$NAMESPACE/ckx-jumphost:$VERSION"
  ["nishanb/ck-x-simulator-remote-terminal:latest"]="$NAMESPACE/ckx-remote-terminal:$VERSION"
  ["nishanb/ck-x-simulator-cluster:latest"]="$NAMESPACE/ckx-cluster:$VERSION"
  ["ckx-facilitator-generated:latest"]="$NAMESPACE/ckx-facilitator:$VERSION"
)

for SRC in "${!MAP[@]}"; do
  DST=${MAP[$SRC]}
  echo "\nTagging $SRC -> $DST"
  docker tag "$SRC" "$DST"
  echo "Pushing $DST"
  docker push "$DST"
done

cat <<EOF

===============================================
Docker Compose override for pulling from Docker Hub
===============================================
Save the following as docker-compose.override.yaml (or a separate file) to use your pushed images:

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

echo "\nDone. Update your override and run: docker compose up -d"

