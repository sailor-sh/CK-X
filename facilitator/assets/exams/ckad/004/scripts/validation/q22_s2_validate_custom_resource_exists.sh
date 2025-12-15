#!/bin/bash
# Q22.02 - Custom Resource instance exists
# Points: 4

# Check if custom resource instance exists
../common/validate_resource_exists.sh backup my-backup crds && {
  echo "✓ Custom Resource instance my-backup exists"
  exit 0
} || {
  echo "✗ Custom Resource instance my-backup not found"
  exit 1
}