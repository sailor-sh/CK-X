#!/bin/bash
# Q02.04 - Contains pods from kube-system namespace
# Points: 3

grep -q "kube-system" /opt/course/1/pod-data.txt && {
  echo "✓ File contains pods from kube-system"
  exit 0
} || {
  echo "✗ No kube-system pods found in file"
  exit 1
}
