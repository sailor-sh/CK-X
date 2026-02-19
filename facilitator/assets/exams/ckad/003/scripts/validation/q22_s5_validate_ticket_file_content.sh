#!/usr/bin/env bash
set -euo pipefail
# Checks if the ticket description file contains a plausible explanation of the issue
TICKET_FILE="/opt/course/exam3/p3/ticket-description.txt"

# Check if file exists
if [ ! -f "$TICKET_FILE" ]; then
    echo "Ticket description file does not exist"
    exit 1
fi

# Check if file is not empty
if [ ! -s "$TICKET_FILE" ]; then
    echo "Ticket description file is empty"
    exit 1
fi

# Check if it contains plausible keywords (readiness, probe, port, etc.)
CONTENT=$(cat "$TICKET_FILE")
if [[ "$CONTENT" != *"readiness"* ]] && [[ "$CONTENT" != *"probe"* ]] && [[ "$CONTENT" != *"port"* ]]; then
    echo "Ticket description does not contain plausible explanation"
    exit 1
fi