#!/bin/bash
# Q02.02 - File is not empty
# Points: 2

[[ -s /opt/course/1/pod-data.txt ]] && {
  echo "✓ File /opt/course/1/pod-data.txt is not empty"
  exit 0
} || {
  echo "✗ File is empty or doesn't exist"
  exit 1
}
