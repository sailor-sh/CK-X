#!/bin/bash
# Q04.02 - Pod has shared volume mounted
# Points: 2

# Source the shared validation library
source "$(dirname "$0")/../validation_lib.sh"

# Check if pod has volumeMounts defined
validate_field_not_empty "pod" "logger-pod" "logging" "{.spec.containers[0].volumeMounts}" "2" "Pod has volume mounts defined" "No volume mounts found"