#!/bin/bash
set -e

# Check base directory structure
BASE_DIR="/tmp/exam/kustomize/base"
if [[ ! -d "$BASE_DIR" ]]; then
    echo "Base directory not found at $BASE_DIR"
    exit 1
fi

# Check overlay directory structure
OVERLAY_DIR="/tmp/exam/kustomize/overlays/production"
if [[ ! -d "$OVERLAY_DIR" ]]; then
    echo "Overlay directory not found at $OVERLAY_DIR"
    exit 1
fi

# Check base kustomization.yaml
if [[ ! -f "$BASE_DIR/kustomization.yaml" ]]; then
    echo "Base kustomization.yaml not found"
    exit 1
fi

# Check base deployment.yaml
if [[ ! -f "$BASE_DIR/deployment.yaml" ]]; then
    echo "Base deployment.yaml not found"
    exit 1
fi

# Check overlay kustomization.yaml
if [[ ! -f "$OVERLAY_DIR/kustomization.yaml" ]]; then
    echo "Overlay kustomization.yaml not found"
    exit 1
fi

# Validate base kustomization.yaml content
BASE_RESOURCES=$(cat "$BASE_DIR/kustomization.yaml" | grep "deployment.yaml")
if [[ -z "$BASE_RESOURCES" ]]; then
    echo "Base kustomization.yaml does not reference deployment.yaml"
    exit 1
fi

# Validate overlay kustomization.yaml content
OVERLAY_CONTENT=$(cat "$OVERLAY_DIR/kustomization.yaml")
if [[ ! "$OVERLAY_CONTENT" =~ "production" ]] || \
   [[ ! "$OVERLAY_CONTENT" =~ "value: 3" ]]; then
    echo "Overlay kustomization.yaml missing required configurations"
    exit 1
fi

echo "Kustomize files validation successful"
exit 0 