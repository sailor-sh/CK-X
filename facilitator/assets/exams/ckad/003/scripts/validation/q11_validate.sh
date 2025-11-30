#!/usr/bin/env bash
set -euo pipefail
LOG=/opt/course/exam3/q11/logs
test -f "$LOG" || { echo "logs file missing"; exit 1; }
grep -q 'SUN_CIPHER_ID' "$LOG" || { echo "logs missing SUN_CIPHER_ID"; exit 1; }
