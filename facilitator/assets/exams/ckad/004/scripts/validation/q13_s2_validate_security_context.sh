#!/bin/bash
# Q13.02 - Pod has security context with runAsUser 2000
# Points: 2

# Source the shared validation library
source "$(dirname "$0")/../validation_lib.sh"

# Check if pod has securityContext.runAsUser set to 2000
validate_field_value "pod" "secure-pod" "security-contexts" "{.spec.securityContext.runAsUser}" "2000" "2" "Pod has runAsUser 2000" "runAsUser not set to 2000"