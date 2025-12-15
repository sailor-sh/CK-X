#!/bin/bash
# Q2.7 - File has reasonable size
# Points: 2

wc -l /opt/course/1/pod-data.txt 2>/dev/null | awk '{print $1}' | grep -q '[1-9]' && {
  echo "✓ File has reasonable size"
  exit 0
} || {
  echo "✗ File size too small"
  exit 1
}
