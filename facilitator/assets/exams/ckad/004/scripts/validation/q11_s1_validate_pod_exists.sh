#!/bin/bash
# Q11.01 - Pod cm-pod exists
# Points: 2

# Source the shared validation library
source "$(dirname "$0")/../validation_lib.sh"

validate_resource_exists "pod" "cm-pod" "configmaps-env" "2" "Pod cm-pod exists" "Pod cm-pod not found"