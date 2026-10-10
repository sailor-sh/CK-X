#!/usr/bin/env bash
set -euo pipefail

TOKEN_FILE="/opt/course/exam3/q05/token"

# This script checks that the token has the valid 3-part JWT structure.
# Fail if the token file is missing or empty.
if [ ! -s "$TOKEN_FILE" ]; then
  exit 1
fi

TOKEN=$(tr -d '\n\r' < "$TOKEN_FILE")
if [[ ! "$TOKEN" =~ ^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$ ]]; then
  exit 1
fi

exit 0
