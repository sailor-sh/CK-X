#!/bin/bash
# Q04.01 - Pod logger-pod exists
# Points: 2

# Source the shared validation library
source "$(dirname "$0")/../validation_lib.sh"

validate_resource_exists "pod" "logger-pod" "logging" "2" "Pod logger-pod exists" "Pod logger-pod not found"