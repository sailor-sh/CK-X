#!/bin/bash
# Q02.01 - File exists at /opt/course/1/pod-data.txt
# Points: 2

test -f /opt/course/1/pod-data.txt && {
  echo "✓ File /opt/course/1/pod-data.txt exists"
  exit 0
} || {
  echo "✗ File /opt/course/1/pod-data.txt not found"
  exit 1
}
