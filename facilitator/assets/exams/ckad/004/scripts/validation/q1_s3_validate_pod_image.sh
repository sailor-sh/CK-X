#!/bin/bash
# Q01.03 - Pod uses nginx:alpine image
# Points: 2

# Source the shared validation library
source "$(dirname "$0")/../validation_lib.sh"

validate_field_value "pod" "web-core" "ckad-ns-a" "{.spec.containers[0].image}" "nginx:alpine" "2" "Pod uses nginx:alpine image" "Pod image incorrect"