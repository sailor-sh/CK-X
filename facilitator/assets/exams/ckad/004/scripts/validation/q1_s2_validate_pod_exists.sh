#!/bin/bash
# Q01.02 - Pod web-core exists in namespace
# Points: 2

# Source the shared validation library
source "$(dirname "$0")/../validation_lib.sh"

validate_resource_exists "pod" "web-core" "ckad-ns-a" "2" "Pod web-core exists in ckad-ns-a" "Pod web-core not found in ckad-ns-a"