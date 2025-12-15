#!/bin/bash
# Q11.02 - Pod uses environment variable from ConfigMap
# Points: 2

# Source the shared validation library
source "$(dirname "$0")/../validation_lib.sh"

# Check if pod has envFrom defined
validate_field_not_empty "pod" "cm-pod" "configmaps-env" "{.spec.containers[0].envFrom}" "2" "Pod has envFrom defined" "No envFrom found"