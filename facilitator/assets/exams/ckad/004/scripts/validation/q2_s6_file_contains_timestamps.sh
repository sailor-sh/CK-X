#!/bin/bash
# Q2.6 - File contains timestamps
# Points: 2

grep -c 'T' /opt/course/1/pod-data.txt 2>/dev/null | grep -q '[1-9]' && {
  echo "✓ File contains timestamps"
  exit 0
} || {
  echo "✗ File missing timestamps"
  exit 1
}
