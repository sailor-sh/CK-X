#!/bin/bash
# Q2.5 - File has correct format
# Points: 2

head -1 /opt/course/1/pod-data.txt 2>/dev/null | grep -q '\t' && {
  echo "✓ File format is correct"
  exit 0
} || {
  echo "✗ File format incorrect"
  exit 1
}
