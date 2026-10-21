#!/usr/bin/env bash
set -euo pipefail
# Ensures the saved YAML is a valid Kubernetes Deployment manifest
YAML_FILE="/opt/course/exam3/q16/cleaner-new.yaml"

# Check if file exists and is not empty
if [ ! -s "$YAML_FILE" ]; then
    echo "YAML file does not exist or is empty"
    exit 1
fi

# Try to apply the YAML with dry-run to validate it
if ! kubectl apply -f "$YAML_FILE" --dry-run=client >/dev/null 2>&1; then
    echo "YAML file is not a valid Kubernetes Deployment manifest"
    exit 1
fi

# Check that it's a Deployment
KIND=$(grep "^kind:" "$YAML_FILE" | awk '{print $2}')
if [ "$KIND" != "Deployment" ]; then
    echo "YAML file is not a Deployment, found kind: $KIND"
    exit 1
fi