#!/usr/bin/env bash
set -euo pipefail
FILE=/opt/course/exam3/q01/namespaces
test -f "$FILE" || { echo "missing namespaces file"; exit 1; }
grep -Eq 'NAME|default' "$FILE" || { echo "file content invalid"; exit 1; }
