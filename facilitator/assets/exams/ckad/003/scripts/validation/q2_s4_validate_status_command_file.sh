#!/usr/bin/env bash
set -euo pipefail

USER_SCRIPT="/opt/course/exam3/q02/pod1-status-command.sh"

# Check if the user's script exists and is executable
if [ ! -x "$USER_SCRIPT" ]; then
    # If not executable, try to make it executable
    chmod +x "$USER_SCRIPT" || exit 1
fi

# Execute the user's script and capture the output
user_output=$("$USER_SCRIPT")

# The PDF provides two valid solutions. One gives `Status: Running` and the other `Running`.
# We will check if the output contains "Running" to validate both.
if [[ "$user_output" == *"Running"* ]]; then
    exit 0
else
    exit 1
fi