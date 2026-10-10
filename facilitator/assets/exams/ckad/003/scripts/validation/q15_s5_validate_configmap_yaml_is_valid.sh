#!/usr/bin/env bash
set -euo pipefail

# Ensure the saved YAML file is a valid Kubernetes ConfigMap manifest
configmap_file="/opt/course/exam3/q15/configmap.yaml"

# Check if file exists
if [[ ! -f "$configmap_file" ]]; then
    echo "ConfigMap YAML file does not exist"
    exit 1
fi

# Try to apply the YAML as a dry-run to validate it
echo "Validating ConfigMap YAML file..."
if kubectl apply --dry-run=client -f "$configmap_file" >/dev/null 2>&1; then
    echo "ConfigMap YAML is valid"
    exit 0
else
    echo "ConfigMap YAML is not valid"
    exit 1
fi