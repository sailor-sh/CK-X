#!/usr/bin/env bash
set -euo pipefail
FILE=/opt/course/exam3/q05/token
test -f "$FILE" && test -s "$FILE" || { echo "token file missing or empty"; exit 1; }
