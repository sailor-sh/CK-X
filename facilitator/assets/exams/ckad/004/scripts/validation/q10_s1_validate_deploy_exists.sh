#!/bin/bash
# Q10.01 - Deployment exists
# Points: 2

# Source the shared validation library
source "$(dirname "$0")/../validation_lib.sh"

validate_resource_exists "deployment" "no-readiness" "cronjobs" "2" "Deployment no-readiness exists" "Deployment not found"