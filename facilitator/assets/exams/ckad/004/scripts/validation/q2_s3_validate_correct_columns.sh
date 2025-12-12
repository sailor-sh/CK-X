#!/bin/bash
# Q02.03 - Two columns present (name, timestamp)
# Points: 3

COLUMNS=$(head -1 /opt/course/1/pod-data.txt 2>/dev/null | wc -w)
[[ "$COLUMNS" -eq 2 ]] && {
  echo "✓ Two columns present in file"
  exit 0
} || {
  echo "✗ Expected 2 columns, found $COLUMNS"
  exit 1
}
