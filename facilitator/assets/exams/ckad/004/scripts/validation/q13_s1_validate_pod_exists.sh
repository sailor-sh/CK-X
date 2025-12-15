#!/bin/bash
# Q13.01 - Pod secure-pod exists
# Points: 2

# Source the shared validation library
source "$(dirname "$0")/../validation_lib.sh"

validate_resource_exists "pod" "secure-pod" "security-contexts" "2" "Pod secure-pod exists" "Pod secure-pod not found"