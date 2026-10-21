#!/usr/bin/env bash
set -euo pipefail

# Ensure the ConfigMap has the data key 'index.html'
configmap_data=$(kubectl -n configmap-web get configmap configmap-web-moon-html -o jsonpath='{.data}')

# Check if index.html key exists in the data
if echo "$configmap_data" | grep -q "index.html"; then
    echo "ConfigMap has index.html data key"
    exit 0
else
    echo "ConfigMap is missing index.html data key"
    exit 1
fi