#!/bin/bash
# Q01.01 - Namespace ckad-ns-a exists
# Points: 2

# Source the shared validation library
source "$(dirname "$0")/../validation_lib.sh"

validate_resource_exists "namespace" "ckad-ns-a" "" "2" "Namespace ckad-ns-a exists" "Namespace ckad-ns-a not found"