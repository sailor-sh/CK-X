#!/usr/bin/env bash
set -euo pipefail
# Executes the script from `sunny_status_command.sh` and checks if it returns success
STATUS_FILE="/opt/course/exam3/p2/sunny_status_command.sh"

# Check if file exists
if [ ! -f "$STATUS_FILE" ]; then
    echo "Status command file does not exist"
    exit 1
fi

# Execute the command and check exit code
if ! bash "$STATUS_FILE" >/dev/null 2>&1; then
    echo "Status command failed or returned non-zero exit code"
    exit 1
fi