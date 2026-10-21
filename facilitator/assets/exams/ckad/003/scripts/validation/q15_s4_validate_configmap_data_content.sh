#!/usr/bin/env bash
set -euo pipefail

# Ensure the content of the 'index.html' key matches the source file
source_content=$(cat /opt/course/exam3/q15/web-moon.html)
configmap_content=$(kubectl -n configmap-web get configmap configmap-web-moon-html -o jsonpath='{.data.index\.html}')

# Compare the content (normalize whitespace for comparison)
if [[ "$(echo "$source_content" | tr -d '[:space:]')" == "$(echo "$configmap_content" | tr -d '[:space:]')" ]]; then
    echo "ConfigMap index.html content matches source file"
    exit 0
else
    echo "ConfigMap index.html content does not match source file"
    exit 1
fi