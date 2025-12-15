#!/bin/bash
# Q10.02 - Readiness probe defined
# Points: 2

# Source the shared validation library
source "$(dirname "$0")/../validation_lib.sh"

validate_probe_defined "deployment" "no-readiness" "cronjobs" "readiness" "0" "2" "Readiness probe defined" "No readiness probe"